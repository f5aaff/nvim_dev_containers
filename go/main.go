package main

import (
    "context"
    "encoding/json"
    "flag"
    "fmt"
    "github.com/docker/docker/api/types"
    "github.com/docker/docker/api/types/container"
    "log"
    "os"
    "os/exec"
    //    "github.com/docker/docker/api/types/network"
    "github.com/docker/docker/client"
    "github.com/docker/docker/pkg/stdcopy"
    "github.com/docker/go-connections/nat"
)

type Config struct {
    DockerPath    string `json:"DOCKER_PATH"`
    Image         string `json:"IMAGE"`
    ContainerName string `json:"CONTAINER_NAME"`
    Port          string `json:"PORT"`
    Offline       bool   `json:"OFFLINE"`
    Packages      string `json:"PACKAGES"`
    PackageOutput string `json:"PACKAGE_OUTPUT"`
}

var config Config

func loadConfig(configPath string) {
    file, err := os.ReadFile(configPath)
    if err != nil {
        log.Fatalf("Failed to read config file: %v", err)
    }

    err = json.Unmarshal(file, &config)
    if err != nil {
        log.Fatalf("Failed to parse config: %v", err)
    }
}

func showHelp() {
    fmt.Println(`Usage: container_manager [options]
Options:
  -h, --help          Prints this message
  -b, --build         Builds the container using DOCKER_PATH from config.json
  -s, --start         Starts the container
  -S, --stop          Stops the container
  -c, --connect       Connects an nvim instance to the container using CONTAINER_NAME and PORT from config.json
`)
}

func buildContainer(cli *client.Client, ctx context.Context) {
    fmt.Println("Building container...")

    // Assuming Dockerfiles are in the specified directory
    buildContextPath := config.DockerPath
    imageName := fmt.Sprintf("%s:latest", config.ContainerName)

    tar, err := os.Open(buildContextPath + "/Dockerfile")
    if err != nil {
        log.Fatalf("Failed to open Dockerfile: %v", err)
    }
    defer tar.Close()

    options := types.ImageBuildOptions{
        Tags:       []string{imageName},
        Dockerfile: "Dockerfile",
        Remove:     true,
    }
    response, err := cli.ImageBuild(ctx, tar, options)
    if err != nil {
        log.Fatalf("Failed to build Docker image: %v", err)
    }
    defer response.Body.Close()

    // Output the build logs
    _, err = stdcopy.StdCopy(os.Stdout, os.Stderr, response.Body)
    if err != nil {
        log.Fatalf("Failed to read build logs: %v", err)
    }
}

func startContainer(config Config) {
    ctx := context.Background()

    // Initialize Docker client
    cli, err := client.NewClientWithOpts(client.FromEnv)
    if err != nil {
        log.Fatalf("Failed to create Docker client: %v", err)
    }

    // Step 1: Declare and initialize ExposedPorts
    exposedPorts := nat.PortSet{
        nat.Port(config.Port + "/tcp"): struct{}{},
    }

    // Step 2: Declare and initialize PortBindings
    portBindings := nat.PortMap{
        nat.Port(config.Port + "/tcp"): []nat.PortBinding{
            {
                HostIP:   "0.0.0.0",
                HostPort: config.Port,
            },
        },
    }

    // Step 3: Create container.Config
    containerConfig := &container.Config{
        Image:        config.Image,
        ExposedPorts: exposedPorts,
    }

    // Step 4: Create container.HostConfig
    hostConfig := &container.HostConfig{
        PortBindings: portBindings,
    }

    // Step 5: Create the container
    resp, err := cli.ContainerCreate(ctx, containerConfig, hostConfig, nil, nil, "")
    if err != nil {
        log.Fatalf("Failed to create container: %v", err)
    }
    log.Printf("Container created with ID: %s", resp.ID)

    // Step 6: Start the container
    err = cli.ContainerStart(ctx, resp.ID, container.StartOptions{})
    if err != nil {
        log.Fatalf("Failed to start container: %v", err)
    }

    log.Printf("Container started successfully with ID: %s", resp.ID)
}

func stopContainer(cli *client.Client, ctx context.Context, config Config) {
    fmt.Println("Stopping container...")

    containerName := config.ContainerName

    timeout := 3000
    stopOptions := container.StopOptions{Signal: "1", Timeout: &timeout}

    // Stop the container
    err := cli.ContainerStop(ctx, containerName, stopOptions)
    if err != nil {
        log.Fatalf("Failed to stop container %s: %v", containerName, err)
    }

    removeOptions := container.RemoveOptions{RemoveVolumes: false, RemoveLinks: false, Force: false}
    // Remove the container
    err = cli.ContainerRemove(ctx, containerName, removeOptions)
    if err != nil {
        log.Fatalf("Failed to remove container %s: %v", containerName, err)
    }

    fmt.Printf("Container %s stopped and removed.\n", containerName)
}

func connectToContainer(cli *client.Client, ctx context.Context) {
    fmt.Println("Connecting to container...")

    containerInfo, err := cli.ContainerInspect(ctx, config.ContainerName)
    if err != nil {
        log.Fatalf("Failed to inspect container: %v", err)
    }

    ip := containerInfo.NetworkSettings.IPAddress
    if ip == "" {
        log.Fatalf("Container IP not found")
    }

    // Assuming nvim is installed on the host and is accessible via PATH
    cmd := exec.Command("nvim", "--server", fmt.Sprintf("%s:%s", ip, config.Port), "--remote-ui")
    cmd.Stdout = os.Stdout
    cmd.Stderr = os.Stderr
    if err := cmd.Run(); err != nil {
        log.Fatalf("Failed to connect nvim: %v", err)
    }
}

func main() {
    var configPath string

    flag.StringVar(&configPath, "C", "config.json", "Path to config.json")
    flag.Parse()

    loadConfig(configPath)

    args := flag.Args()
    if len(args) < 1 {
        showHelp()
        os.Exit(1)
    }

    ctx := context.Background()
    cli, err := client.NewClientWithOpts(client.FromEnv)
    if err != nil {
        log.Fatalf("Failed to create Docker client: %v", err)
    }
    defer cli.Close()

    switch args[0] {
    case "-h", "--help":
        showHelp()
    case "-b", "--build":
        buildContainer(cli, ctx)
    case "-s", "--start":
        startContainer(config)
    case "-S", "--stop":
        stopContainer(cli, ctx, config)
    case "-c", "--connect":
        connectToContainer(cli, ctx)
    default:
        fmt.Printf("Invalid argument: %s\n", args[0])
        showHelp()
        os.Exit(1)
    }
}
