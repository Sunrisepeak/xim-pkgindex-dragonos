function github_scode(version) return string.format("https://github.com/DragonOS-Community/DragonOS/archive/refs/tags/V%s.tar.gz", version) end
-- https://git.mirrors.dragonos.org.cn/explore/repos
function mirror_scode(version) return string.format("https://git.mirrors.dragonos.org.cn/DragonOS-Community/DragonOS/archive/V%s.tar.gz", version) end

package = {
    homepage = "https://dragonos.org",

    -- base info
    name = "dragonos-scode",
    description = "DragonOS Project Source Code",

    maintainers = "https://community.dragonos.org/governance/staff-info.html",
    contributors = "https://github.com/DragonOS-Community/DragonOS/graphs/contributors",
    license = "GPL-2.0",
    repo = "https://github.com/DragonOS-Community/DragonOS",
    docs = "https://docs.dragonos.org.cn",

    -- xim pkg info
    type = "package",
    namespace = "dragonos",

    xpm = {
        linux = {
            ["latest"] = { ref = "0.2.0" },
            ["0.2.0"] = {
                url = {
                    GLOBAL = github_scode("0.2.0"),
                    CN = mirror_scode("0.2.0"),
                },
                sha256 = nil
            }
        },
    },
}

import("xim.libxpkg.log")
import("xim.libxpkg.pkginfo")
import("xim.libxpkg.xvm")

function installed()
    if xvm.has("dragonos-scode") then
        return os.isfile(path.join(pkginfo.install_dir(), "Makefile"))
    end
    return false
end

function install()

    local scodedir = "dragonos" -- mirror style

    if not os.isdir(scodedir) then
        log.info("use github style scode dir...")
        scodedir = "DragonOS-" .. pkginfo.version() -- github style
    end

    os.tryrm(pkginfo.install_dir())
    os.trymv(scodedir, pkginfo.install_dir())

    xvm.add("dragonos-scode")

    return installed() -- check again
end

function config()
    __append_patch()
    return true
end

function uninstall()
    xvm.remove("dragonos-scode")
    return true
end

-- private

function __append_patch()

    if pkginfo.version() == "0.2.0" then
        log.info("patch write_disk_image.sh for busybox init...")
        local write_disk_image = path.join(pkginfo.install_dir(), "tools/write_disk_image.sh")
        if os.isfile(write_disk_image) then
            local content = io.readfile(write_disk_image)
            content = content:replace("init=/bin/dragonreach", "init=/bin/busybox init")
            io.writefile(write_disk_image, content)
        else
            log.warn("cannot find write-disk-image.sh to patch")
        end
    end

end