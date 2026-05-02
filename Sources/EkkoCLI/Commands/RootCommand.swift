import ArgumentParser
import EkkoCore

struct RootCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ekko",
        abstract: "Ekko — incremental backup tool for macOS.",
        version: EkkoVersion.current,
        subcommands: [AgentTriggerCommand.self]
    )
}
