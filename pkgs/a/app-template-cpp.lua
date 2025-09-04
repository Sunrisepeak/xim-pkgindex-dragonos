package = {
    -- base info
    name = "app-template-cpp",
    description = "DragonOS Application Project Template - C++",

    license = "Apache-2.0",
    repo = "https://github.com/Sunrisepeak/dragonos-app-template-cpp",

    -- xim pkg info
    type = "template",
    namespace = "dragonos",

    xpm = {
        linux = {
            ["latest"] = { ref = "0.0.1" },
            ["0.0.1"] = {
                url = "https://github.com/Sunrisepeak/dragonos-app-template-cpp.git",
                sha256 = nil
            }
        },
    },
}

import("xim.libxpkg.pkginfo")
import("xim.libxpkg.xvm")

function installed()
    return xvm.has("dragonos-app-template-cpp")
end

function install()

    os.tryrm(pkginfo.install_dir())
    os.trymv("dragonos-app-template-cpp", pkginfo.install_dir())

    xvm.add("dragonos-app-template-cpp")

    return installed() -- check again
end

function uninstall()
    xvm.remove("dragonos-app-template-cpp")
    return true
end