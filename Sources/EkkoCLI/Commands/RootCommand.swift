import ArgumentParser
import EkkoCore
import EkkoPlatform

struct RootCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ekko",
        abstract: "Ekko — incremental backup tool for macOS.",
        version: EkkoVersion.current,
        subcommands: [AgentTriggerCommand.self]
    )
}
