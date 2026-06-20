package main

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/spf13/cobra"
	"gopkg.in/yaml.v3"
)

// These variables will be set during the build process using ldflags to include version information.
var (
	version   = "dev"
	buildOS   = "unknown"
	buildArch = "unknown"
	buildTime = "unknown"
)

type bucketConfig struct {
	Name         string
	Source       string
	Destination  string
	RsyncOptions string
}

type appConfig struct {
	General map[string]string
	Buckets map[string]bucketConfig
}

type yamlBucketConfig struct {
	Name         string `yaml:"name"`
	Source       string `yaml:"src"`
	Destination  string `yaml:"dest"`
	RsyncOptions string `yaml:"rsync_options"`
}

type yamlAppConfig struct {
	LogDir  string             `yaml:"log_dir"`
	Buckets []yamlBucketConfig `yaml:"buckets"`
}

type options struct {
	AutoConfirm bool
	DryRun      bool
	Reverse     bool
	Verbose     bool
	ConfigFile  string
}

type logger struct {
	debug bool
	out   io.Writer
	err   io.Writer
}

func newLogger(debug bool) *logger {
	return &logger{debug: debug, out: os.Stdout, err: os.Stderr}
}

func (l *logger) Debug(msg string) {
	if l.debug {
		fmt.Fprintln(l.out, "DEBUG: "+msg)
	}
}

func (l *logger) Debugf(format string, args ...any) {
	if l.debug {
		fmt.Fprintf(l.out, "DEBUG: "+format+"\n", args...)
	}
}

func (l *logger) Log(msg string) {
	fmt.Fprintln(l.out, msg)
}

func (l *logger) Logf(format string, args ...any) {
	fmt.Fprintf(l.out, format+"\n", args...)
}

func (l *logger) Info(msg string) {
	fmt.Fprintln(l.out, "INFO: "+msg)
}

func (l *logger) Infof(format string, args ...any) {
	fmt.Fprintf(l.out, "INFO: "+format+"\n", args...)
}

func (l *logger) Warn(msg string) {
	fmt.Fprintln(l.err, "WARNING: "+msg)
}

func (l *logger) Warnf(format string, args ...any) {
	fmt.Fprintf(l.err, "WARNING: "+format+"\n", args...)
}

var log *logger

func main() {
	homeDir, _ := os.UserHomeDir()
	defaultConfig := os.Getenv("SYNQ_CONF")
	if defaultConfig == "" {
		defaultConfig = filepath.Join(homeDir, ".synq", "synq.yml")
	}

	opts := options{ConfigFile: defaultConfig}

	rootCmd := &cobra.Command{
		Use:   "synq [flags] [bucket1 bucket2 ...]",
		Short: "Synchronize multiple directories (buckets) using rsync",
		Long: "Synchronize multiple directories (buckets) using rsync.\n\n" +
			"If no bucket names are provided, all buckets defined in the configuration are synced.\n" +
			"rsync output is logged to a file if 'log_dir' is configured in the YAML file.",
		Version:      fmt.Sprintf("%s (%s/%s) built at %s", version, buildOS, buildArch, buildTime),
		SilenceUsage: true,
		Args:         cobra.ArbitraryArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			if len(args) == 0 && cmd.Flags().NFlag() == 0 {
				return cmd.Help()
			}

			log = newLogger(opts.Verbose)

			log.Debugf("Checking for rsync command in PATH...")
			if _, err := exec.LookPath("rsync"); err != nil {
				return fmt.Errorf("rsync command could not be found")
			}
			log.Debugf("rsync command found.")

			log.Debugf("Parsing configuration file: %s", opts.ConfigFile)
			cfg, err := parseConfig(opts.ConfigFile)
			if err != nil {
				return err
			}

			log.Debugf("Parsed configuration: %+v", cfg)

			if opts.Verbose {
				printConfigSummary(log, cfg, opts, args)
			}

			log.Debugf("Selecting buckets to sync based on provided arguments: %+v", args)
			selectedBuckets := selectBuckets(log, cfg.Buckets, args)
			log.Debugf("Selected buckets: %+v", selectedBuckets)
			if len(selectedBuckets) == 0 {
				return errors.New("no valid buckets to sync")
			}

			log.Debugf("Starting synchronization of selected buckets...")
			return syncBuckets(log, cfg, opts, selectedBuckets)
		},
	}

	rootCmd.Flags().BoolVarP(&opts.AutoConfirm, "yes", "y", false, "Skip confirmation prompt")
	rootCmd.Flags().BoolVarP(&opts.DryRun, "dry-run", "n", false, "Run in dry-run mode")
	rootCmd.Flags().BoolVarP(&opts.Reverse, "reverse", "r", false, "Reverse sync (destination becomes source)")
	rootCmd.Flags().BoolVarP(&opts.Verbose, "verbose", "v", false, "Enable verbose output")
	rootCmd.Flags().StringVarP(&opts.ConfigFile, "config", "c", opts.ConfigFile, "Path to the configuration file")

	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func parseConfig(configPath string) (appConfig, error) {
	fileExtension := strings.ToLower(filepath.Ext(configPath))
	if fileExtension != ".yaml" && fileExtension != ".yml" {
		return appConfig{}, fmt.Errorf("configuration file must be a .yaml or .yml file: %s", configPath)
	}

	file, err := os.Open(configPath)
	if err != nil {
		return appConfig{}, fmt.Errorf("configuration file not found: %s", configPath)
	}
	defer file.Close()

	var parsedConfig yamlAppConfig
	decoder := yaml.NewDecoder(file)
	decoder.KnownFields(true)
	if err := decoder.Decode(&parsedConfig); err != nil {
		return appConfig{}, fmt.Errorf("failed to parse YAML configuration file: %w", err)
	}

	cfg := appConfig{
		General: map[string]string{},
		Buckets: map[string]bucketConfig{},
	}

	if strings.TrimSpace(parsedConfig.LogDir) != "" {
		cfg.General["log_dir"] = strings.TrimSpace(parsedConfig.LogDir)
	}

	for index, bucket := range parsedConfig.Buckets {
		bucketName := ""
		if strings.TrimSpace(bucket.Name) != "" {
			bucketName = strings.TrimSpace(bucket.Name)
		} else {
			bucketName = fmt.Sprintf("bucket%d", index+1)
		}
		cfg.Buckets[bucketName] = bucketConfig{
			Source:       strings.TrimSpace(bucket.Source),
			Destination:  strings.TrimSpace(bucket.Destination),
			RsyncOptions: strings.TrimSpace(bucket.RsyncOptions),
		}
	}

	return cfg, nil
}

func printConfigSummary(log *logger, cfg appConfig, opts options, requestedBuckets []string) {
	log.Log("-------------------------------------------")
	log.Logf("Configuration file: %s", opts.ConfigFile)
	log.Log("Options:")
	log.Logf("  Auto confirm: %t", opts.AutoConfirm)
	log.Logf("  Dry run:      %t", opts.DryRun)
	log.Logf("  Reverse:      %t", opts.Reverse)
	log.Log("-------------------------------------------")

	bucketNames := make([]string, 0, len(cfg.Buckets))
	for name := range cfg.Buckets {
		bucketNames = append(bucketNames, name)
	}
	sort.Strings(bucketNames)

	log.Log("Buckets:")
	log.Log("-------------------------------------------")
	for _, name := range bucketNames {
		bucket := cfg.Buckets[name]
		log.Logf("Bucket: %s", name)
		log.Logf("Source: %s", bucket.Source)
		log.Logf("Destination: %s", bucket.Destination)
		log.Logf("Rsync Options: %s", bucket.RsyncOptions)
		log.Log("")
	}

	if len(requestedBuckets) == 0 {
		log.Info("No buckets specified; all buckets will be synced.")
	} else {
		log.Debugf("Buckets requested: %s", strings.Join(requestedBuckets, " "))
	}
}

func selectBuckets(log *logger, allBuckets map[string]bucketConfig, requested []string) []string {
	if len(requested) == 0 {
		names := make([]string, 0, len(allBuckets))
		for name := range allBuckets {
			names = append(names, name)
		}
		sort.Strings(names)
		return names
	}

	selected := make([]string, 0, len(requested))
	for _, name := range requested {
		if _, ok := allBuckets[name]; ok {
			selected = append(selected, name)
		} else {
			log.Warnf("%s is not a valid bucket and will be ignored.", name)
		}
	}
	return selected
}

func syncBuckets(log *logger, cfg appConfig, opts options, buckets []string) error {
	logDir := strings.TrimSpace(cfg.General["log_dir"])
	if logDir != "" {
		if err := ensureLogDir(log, logDir, opts.AutoConfirm); err != nil {
			return err
		}
	}

	log.Debugf("Buckets to sync: %s", strings.Join(buckets, " "))

	for _, bucketName := range buckets {
		bucket := cfg.Buckets[bucketName]
		if bucket.Source == "" {
			log.Warnf("bucket [%s] does not exist in the configuration.", bucketName)
			continue
		}

		source := bucket.Source
		destination := bucket.Destination
		if opts.Reverse {
			source, destination = destination, source
		}

		log.Log("---------------------------------------------------")
		log.Logf("Bucket: %s", bucketName)
		log.Logf("  Source:      %s", source)
		log.Logf("  Destination: %s", destination)
		if strings.TrimSpace(bucket.RsyncOptions) != "" {
			log.Logf("  Rsync opts:  %s", bucket.RsyncOptions)
		}
		if opts.Reverse {
			log.Log("  (Reversed sync: destination -> source)")
		}
		log.Log("---------------------------------------------------")

		if !opts.AutoConfirm {
			confirmed, err := askForConfirmation(fmt.Sprintf("Sync bucket '%s'?", bucketName))
			if err != nil {
				return err
			}
			if !confirmed {
				log.Infof("Skipping bucket '%s'.", bucketName)
				continue
			}
		}

		cmdArgs := []string{"-av"}
		if opts.DryRun {
			cmdArgs = append(cmdArgs, "--dry-run")
		}
		if strings.TrimSpace(bucket.RsyncOptions) != "" {
			cmdArgs = append(cmdArgs, strings.Fields(bucket.RsyncOptions)...)
		}
		cmdArgs = append(cmdArgs, source, destination)

		logFile := ""
		if logDir != "" {
			timestamp := time.Now().Format("20060102-150405")
			logFile = filepath.Join(logDir, fmt.Sprintf("synq_%s_%s.log", bucketName, timestamp))
		}

		log.Debugf("Executing rsync %s", strings.Join(cmdArgs, " "))
		if err := runRsync(log, cmdArgs, logFile); err != nil {
			return err
		}
	}

	return nil
}

func runRsync(log *logger, args []string, logFile string) error {
	cmd := exec.Command("rsync", args...)

	if logFile == "" {
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
	} else {
		f, err := os.Create(logFile)
		if err != nil {
			return fmt.Errorf("failed to create log file %s: %w", logFile, err)
		}
		defer f.Close()
		writer := io.MultiWriter(os.Stdout, f)
		log.Infof("Rsync output will be logged to: %s", logFile)
		cmd.Stdout = writer
		cmd.Stderr = writer
	}
	cmd.Stdout.Write([]byte(fmt.Sprintf("INFO: Rsync command: rsync %s\n", strings.Join(args, " "))))

	return cmd.Run()
}

func ensureLogDir(log *logger, logDir string, autoConfirm bool) error {
	if fileInfo, err := os.Stat(logDir); err == nil && fileInfo.IsDir() {
		return nil
	}

	if !autoConfirm {
		confirmed, err := askForConfirmation(fmt.Sprintf("Directory [%s] does not exist, do you want to create it?", logDir))
		if err != nil {
			return err
		}
		if !confirmed {
			return nil
		}
	}

	log.Infof("Creating [%s] directory", logDir)
	if err := os.MkdirAll(logDir, 0o755); err != nil {
		return fmt.Errorf("failed to create log directory %s: %w", logDir, err)
	}
	log.Infof("Created [%s] directory", logDir)
	return nil
}

func askForConfirmation(prompt string) (bool, error) {
	fmt.Printf("%s (y/N): ", prompt)
	reader := bufio.NewReader(os.Stdin)
	input, err := reader.ReadString('\n')
	if err != nil && !errors.Is(err, io.EOF) {
		return false, err
	}

	answer := strings.TrimSpace(input)
	return strings.EqualFold(answer, "y"), nil
}
