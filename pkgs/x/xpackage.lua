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
    ["--nographic"]
}

function help_info()
    cprint("${bright green}DragonOS Helper Tool${clear}")
    cprint("")
    cprint("Usage: ${bright yellow}dragonos-tool <command> [options]${clear}")
    cprint("")
    cprint("Commands:")
    cprint("  ${bright yellow}init${clear}          Initialize DragonOS development environment")
    cprint("  ${bright yellow}build${clear}         Build the DragonOS project")
    cprint("  ${bright yellow}run${clear}           Run the DragonOS project in QEMU")
    cprint("  ${bright yellow}clean${clear}         Clean build artifacts")
    cprint("")
    cprint("Options:")
    cprint("  ${bright yellow}--nographic${clear}   Run QEMU in nographic mode (no GUI)")
    cprint("")
    cprint("Example:")
    cprint("  ${bright yellow}dragonos-tool init${clear}");
    cprint("  ${bright yellow}dragonos-tool run${clear}");
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

    if action == "init" then
        pkgmanager.install("dragonos:dragonos-dev")
        
    elseif action == "build" then
        system.exec("make build")
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