package = {
    -- base info
    name = "dragonos-tool",
    description = "DragonOS Helper Tool",

    license = "Apache-2.0",
    repo = "https://github.com/Sunrisepeak/xim-pkgindex-dragonos",

    -- xim pkg info
    type = "script",
    namespace = "dragonos",
    programs = { "dragonos-tool" },

    xpm = {
        linux = {
            deps = { "make" },
            ["latest"] = { ref = "0.0.1" },
            ["0.0.1"] = { },
        },
    },
}

import("xim.libxpkg.utils")
import("xim.libxpkg.system")
import("xim.libxpkg.pkgmanager")
import("xim.libxpkg.xvm")
import("xim.libxpkg.log")

local __xscript_input = {
    -- build
    ["--only-diskimg"] = false,
    -- run
    ["--nographic"] = false,
}

function help_info()
    cprint("${green}%s - 0.0.1${clear}", package.description)
    cprint("")
    cprint("Usage: ${dim cyan}dragonos-tool <command> [options]${clear}")
    cprint("")
    cprint("Commands:")
    cprint("  ${dim cyan}init${clear}          Initialize DragonOS development environment")
    cprint("  ${dim cyan}build${clear}         Build the DragonOS project")
    cprint("  ${dim cyan}run${clear}           Run the DragonOS project in QEMU")
    cprint("  ${dim cyan}clean${clear}         Clean build artifacts")
    cprint("")
    cprint("Options:")
    cprint("  ${dim cyan}--nographic${clear}   Run QEMU in nographic mode (no GUI)")
    cprint("  ${dim cyan}--only-diskimg${clear}Update disk image - sysroot")
    cprint("")
    cprint("Example:")
    cprint("  ${dim cyan}dragonos-tool init${clear}");
    cprint("  ${dim cyan}dragonos-tool run${clear}");
    cprint("")
end

function set_dadk_version()
    log.info("Setting DADK version...")
    local user_makefile = path.join(system.rundir(), "user/Makefile")
    if os.isfile(user_makefile) then
        local content = io.readfile(user_makefile)
        -- MIN_DADK_VERSION = 0.4.0
        local version = content:match("MIN_DADK_VERSION%s*=%s*([%d%.]+)")
        if version then
            log.info("Found MIN_DADK_VERSION: " .. version)
            if not xvm.has("dadk", version) then
                pkgmanager.install("dragonos:dadk@" .. version)
            end
            xvm.use("dadk", version)
        else
            log.error("DADK version not found in Makefile")
        end
    else
        log.error("Makefile not found  - " .. user_makefile)
        log.warn("Please run [dragonos-tool] in project root directory")
    end
end

function xpkg_main(action, ...)

    local _, cmds = utils.input_args_process(
        __xscript_input,
        { ... }
    )

    os.cd(system.rundir())

    if action == "init" then
        pkgmanager.install("dragonos:dragonos-dev")
        set_dadk_version()
    elseif action == "build" then
        if cmds["--only-diskimg"] then
            system.exec("make write_diskimage")
        else
            system.exec("make build")
        end
    elseif action == "run" then
        if cmds["--nographic"] then
            system.exec("make qemu-nographic")
        else
            system.exec("make qemu")
        end
    elseif action == "clean" then
        system.exec("make clean")
    else
        help_info()
    end

end