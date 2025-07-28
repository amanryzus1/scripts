// GameBooster - Real-time process killer for better gaming performance
// Author: Anshuman
// Purpose: Keep your game(s) running smooth by killing resource-hungry background processes
package main

import (
    "bufio"
    "fmt"
    "log"
    "os"
    "strings"
    "time"

    "github.com/shirou/gopsutil/process"
)

const (
    whitelistFile = "whitelist.txt"
    cpuLimit      = 20.0               // % CPU usage
    ramLimitMB    = 300                // RAM in MB
    interval      = 10 * time.Second   // Check every 10 seconds
)

func loadWhitelist(filename string) map[string]bool {
    whitelist := make(map[string]bool)
    file, err := os.Open(filename)
    if err != nil {
        log.Fatalf("Failed to read whitelist: %v", err)
    }
    defer file.Close()

    scanner := bufio.NewScanner(file)
    for scanner.Scan() {
        proc := strings.TrimSpace(scanner.Text())
        if proc != "" {
            whitelist[strings.ToLower(proc)] = true
        }
    }
    return whitelist
}

func monitorAndKill(whitelist map[string]bool) {
    procs, err := process.Processes()
    if err != nil {
        log.Printf("Error getting processes: %v", err)
        return
    }

    for _, p := range procs {
        name, err := p.Name()
        if err != nil {
            continue
        }
        nameLower := strings.ToLower(name)

        if nameLower == "gamebooster.exe" || whitelist[nameLower] {
            continue
        }

        cpu, _ := p.CPUPercent()
        mem, _ := p.MemoryInfo()

        if cpu > cpuLimit || (mem != nil && mem.RSS > uint64(ramLimitMB*1024*1024)) {
            fmt.Printf("Killing: %s (CPU: %.1f%%, RAM: %.1fMB)\n",
                name, cpu, float64(mem.RSS)/1024/1024)
            _ = p.Kill() // Fail silently
        }
    }
}

func main() {
    whitelist := loadWhitelist(whitelistFile)
    fmt.Println("🎮 Game Booster running... (press Ctrl+C to exit)")

    for {
        monitorAndKill(whitelist)
        time.Sleep(interval)
    }
}
