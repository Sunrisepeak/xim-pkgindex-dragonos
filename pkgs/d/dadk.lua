package = {
    homepage = "https://dragonos.org",

    -- base info
    name = "dadk",
    description = "DADK - DragonOS Application Development Kit",

    maintainers = "DragonOS Community",
    license = "GPL-2.0",
    repo = "https://github.com/DragonOS-Community/DADK",
    docs = "https://docs.dragonos.org.cn/p/dadk",

    -- xim pkg info
    type = "apps",

    programs = { "dadk" },

    xpm = {
        linux = {
            deps = { "rust" },
            ["latest"] = { ref = "0.4.0" },
            ["0.4.0"] = { },
            ["0.3.0"] = { },
            ["0.2.0"] = { },
        },
    },
}

import("xim.libxpkg.pkginfo")
import("xim.libxpkg.system")
import("xim.libxpkg.xvm")

function install()

    system.exec("xvm workspace global --active false")
        system.exec("cargo install --git"
            .. " https://git.mirrors.dragonos.org.cn/DragonOS-Community/DADK.git"
            .. " --tag"
            .. " v" .. pkginfo.version()
            .. " --root " .. pkginfo.install_dir()
        )
    system.exec("xvm workspace global --active true")

    return true
end

function config()
    xvm.add("dadk", { bindir = path.join(pkginfo.install_dir(), "bin") })
    return true
end

function uninstall()
    xvm.remove("dadk")
    return true
end