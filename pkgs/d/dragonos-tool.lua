package = {
    -- base info
    name = "dragonos-tool",
    description = "DragonOS Helper Tool",

    license = "Apache-2.0",
    repo = "https://github.com/Sunrisepeak/xim-pkgindex-dragonos",

    -- xim pkg info
    type = "script",
    namespace = "dragonos",
    programs = { "dragonos-tool", "dotool" },

    xpm = {
        linux = {
            deps = { "make", "xpkg-helper", "python@3" },
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
import("xim.libxpkg.pkginfo")

-- function install (default - dragonos-tool)

function config()
    xvm.add("dotool", {
        alias = "dragonos-tool",
        binding = "dragonos-tool@" .. pkginfo.version(),
    })
    return true
end

function uninstall()
    xvm.remove("dotool")
    xvm.remove("dragonos-tool")
    return true
end

--- script

local __xscript_input = {
    -- build
    ["--only-diskimg"] = false,
    -- run
    ["--nographic"] = false,
    ["--project-dir"] = false,
}

local dotool_config_file = path.join(os.scriptdir(), ".dotool")
local project_makefile = path.join("Makefile")
local project_user_makefile = path.join("user/Makefile")

function help_info()
    cprint("${green}%s - 0.0.1${clear}", package.description)
    cprint("")
    cprint("Usage: ${dim cyan}dragonos-tool <command> [options]${clear}")
    cprint("")
    cprint("Commands:")
    cprint("  ${dim cyan}init${clear}          Initialize DragonOS development environment")
    cprint("  ${dim cyan}build${clear}         Build the DragonOS project")
    cprint("  ${dim cyan}run${clear}           Run the DragonOS project in QEMU")
    cprint("  ${dim cyan}export${clear}        Export DragonOS source code to current directory")
    cprint("  ${dim cyan}install${clear}       Install a binary to the DragonOS sysroot")
    cprint("  ${dim cyan}clean${clear}         Clean build artifacts")
    cprint("")
    cprint("Options:")
    cprint("  ${dim cyan}--nographic${clear}     Run QEMU in nographic mode (no GUI)")
    cprint("  ${dim cyan}--only-diskimg${clear}  Update disk image - sysroot")
    cprint("  ${dim cyan}--project-dir=DIR${clear} Specify the DragonOS project directory (default: current directory)")
    cprint("")
    cprint("Example:")
    cprint("  ${dim cyan}dragonos-tool init${clear}");
    cprint("  ${dim cyan}dragonos-tool run${clear}");
    cprint("  ${dim cyan}dragonos-tool install path/to/binary");
    cprint("")
end

function set_dadk_version()
    log.info("Setting DADK version...")
    if os.isfile(project_user_makefile) then
        local content = io.readfile(project_user_makefile)
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
        log.error("Makefile not found  - " .. project_user_makefile)
    end
end

function action_init(cmds)

    local projectdir = cmds["--project-dir"] or os.curdir()

    pkgmanager.install("dragonos:dragonos-dev")

    log.info("Checking project...")

    if os.isfile(project_makefile) then
        log.info("Project Makefile found...")
    else
        log.warn("Project not found, install DragonOS source code...")
        if not xvm.has("dragonos:dragonos-scode", "") then
            pkgmanager.install("dragonos:dragonos-scode")
        end

        local info = xvm.info("dragonos-scode", "")
        projectdir = path.join(
            os.scriptdir(),
            "dragonos@" .. info["Version"]
        )

        system.exec(
            "xpkg-helper dragonos:dragonos-scode"
            .. " --export-path " .. projectdir
        )

        os.cd(projectdir)

        io.writefile(dotool_config_file, projectdir)
    end

    log.info("Setting up Python environment...")
    -- TODO: use python3 -m venv
    system.exec("pip3 install --break-system-packages -r docs/requirements.txt", { retry = 3})

    set_dadk_version()

    log.info("${bright}DragonOS | ${yellow}%s${clear} - ${green}ok", projectdir)
end

function action_app_install(cmds)

    local binfile = cmds.binfile
    local dstpath = cmds.dstpath

    local fname = path.filename(binfile)
    local sysroot_dir = path.join(cmds["--project-dir"], "bin/sysroot")

    if not os.isdir(sysroot_dir) and os.isfile(dotool_config_file) then
        cmds["--project-dir"] = io.readfile(dotool_config_file)
        sysroot_dir = path.join(cmds["--project-dir"], "bin/sysroot")
    end

    if not os.isdir(sysroot_dir) then
        log.error("System root directory not found - " .. sysroot_dir)
        log.warn("Please run '${cyan}dragonos-tool init && dragonos-tool build${clear}' first to set up the environment.")
        return
    end

    if not os.isfile(binfile) then
        log.error("Source binary file not found: " .. binfile)
        return
    end

    dstpath = path.join(dstpath or "bin", fname)

    log.info("Copying %s to %s", binfile, path.join(sysroot_dir, dstpath))

    os.cp(binfile, path.join(sysroot_dir, dstpath))

    log.info("update disk image...")

    system.exec("dotool build --only-diskimg --project-dir " .. cmds["--project-dir"])

    log.info("${bright}Install to sysroot - ${yellow}%s${clear} - ${green}ok", dstpath)
end

function xpkg_main(action, ...)

    local _, cmds = utils.input_args_process(
        __xscript_input,
        { ... }
    )

    if not cmds["--project-dir"] then
        cmds["--project-dir"] = os.curdir()
    end

    if action == "init" then
        action_init(cmds)
    elseif action == "export" then
        system.exec("xpkg-helper dragonos:dragonos-scode")
    elseif action == "install" then
        local args = { ... }
        if #args < 1 then
            log.error("dograonos-tool install [src-binary] <dst-path-dir>")
            return
        end

        cmds.binfile = args[1]
        cmds.dstpath = args[2]

        action_app_install(cmds)

    else

        os.cd(cmds["--project-dir"])

        if not os.isfile(project_makefile) then
            local default_projectdir
            if os.isfile(dotool_config_file) then default_projectdir = io.readfile(dotool_config_file) end
            if default_projectdir and os.isdir(default_projectdir) then
                os.cd(default_projectdir)
                cmds["--project-dir"] = default_projectdir
                log.warn("Changed to default project directory: " .. default_projectdir)
            else
                log.error("Project Makefile not found - try to run:")
                cprint("")
                cprint("  ${dim cyan}dragonos-tool init${clear}");
                cprint("")
                return
            end
        end

        if action == "build" then
            if cmds["--only-diskimg"] then
                system.exec("make write_diskimage")
            else
                system.exec("make build", { retry = 3 })
            end
        elseif action == "run" then

            if not os.isfile("bin/disk-image-x86_64.img") then
                log.warn("os disk-image not found, building os disk-image first...")
                log.info("try to run [ dragonos-tool build ] build${blink}...")
                os.sleep(3000)
                system.exec("dragonos-tool build")
            end

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

end