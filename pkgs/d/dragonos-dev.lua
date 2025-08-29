function github_scode(version) return string.format("https://github.com/DragonOS-Community/DragonOS/archive/refs/tags/V%s.tar.gz", version) end

package = {
    homepage = "https://dragonos.org",

    -- base info
    name = "dragonos-dev",
    description = "DragonOS Development Environment",

    maintainers = "https://community.dragonos.org/governance/staff-info.html",
    contributors = "https://github.com/DragonOS-Community/DragonOS/graphs/contributors",
    license = "GPL-2.0",
    repo = "https://github.com/DragonOS-Community/DragonOS",
    docs = "https://docs.dragonos.org.cn",

    -- xim pkg info
    type = "config",
    namespace = "config",

    xpm = {
        debian = {
            deps = { "make", "rust", "python@3", "musl-gcc", "qemu@10", "dadk@0.4" },
            ["0.2.0"] = {
                url = {
                    GLOBAL = github_scode("0.2.0"),
                    CN = github_scode("0.2.0"), -- TODO
                },
                sha256 = nil,
            },
        },
    },
}

import("xim.libxpkg.log")
import("xim.libxpkg.pkginfo")
import("xim.libxpkg.system")
import("xim.libxpkg.pkgmanager")

local install_file = "install-info.xim"

local RUST_VERSION = "nightly-2025-08-10"
local RUST_VERSION_OLD = "nightly-2024-11-05"

function installed()
    local installdir = pkginfo.install_dir()
    local install_file_path = path.join(installdir, install_file)
    if os.isfile(install_file_path) then
        local real_installdir = io.readfile(install_file_path)
        if os.isdir(real_installdir) then
            log.info("install dir: %s", real_installdir)
            return true
        end
    end
    return false
end

function install()
    local scode_dir = "DragonOS-" .. pkginfo.version()
    local real_installdir = path.join(system.rundir(), scode_dir)

    -- 0.rust toolchain and components
    log.info("0 - install rust toolchain and components")
    __rust_components_install()

    log.info("1 - install dir(source code): %s", real_installdir)
    os.trymv(scode_dir, real_installdir)

    -- 2.python package
    log.info("2 - install python package")
    os.cd(real_installdir)
    -- TODO: use python3 -m venv
    system.exec("pip3 install --break-system-packages -r docs/requirements.txt", { retry = 3})

    -- 3.create install_file
    io.writefile(path.join(pkginfo.install_dir(), install_file), real_installdir)

    return true
end

function config()

    log.info("1 - config kvm permission for current user")

    local current_user = os.getenv("USER")

    -- if not in kvm group, add it
    if string.find(os.iorun("groups " .. current_user), "kvm", 1, true) then
        log.info("user [%s] is already in kvm group", current_user)
    else
        log.info("adding user [%s] to kvm group", current_user)
        os.exec("sudo usermod -aG kvm " .. current_user)
    end

    return true
end

function uninstall()
    return true
end

-- private function

function __rust_components_install(component)

    -- config rustup mirror (tmp)
    pkgmanager.install("rustup-mirror")

    local components = {
        [[rustup toolchain install %s-x86_64-unknown-linux-gnu]],
        [[rustup component add rust-src --toolchain %s-x86_64-unknown-linux-gnu]],
        [[rustup target add x86_64-unknown-none --toolchain %s-x86_64-unknown-linux-gnu]],
        [[rustup target add x86_64-unknown-linux-musl --toolchain %s-x86_64-unknown-linux-gnu]],
        [[rustup target add riscv64gc-unknown-none-elf --toolchain %s-x86_64-unknown-linux-gnu]],
        [[rustup target add riscv64imac-unknown-none-elf --toolchain %s-x86_64-unknown-linux-gnu]],
        [[rustup target add riscv64gc-unknown-linux-musl --toolchain %s-x86_64-unknown-linux-gnu]],
        [[rustup target add loongarch64-unknown-none --toolchain %s-x86_64-unknown-linux-gnu]],
    }

    for _, cmd in ipairs(components) do
        local fullcmd = string.format(cmd, RUST_VERSION)
        local old_fullcmd = string.format(cmd, RUST_VERSION_OLD)
        log.info("exec: %s", fullcmd)
        system.exec(fullcmd, { retry = 3 })
        log.info("exec: %s", old_fullcmd)
        system.exec(old_fullcmd, { retry = 3 })
    end

    system.exec("rustup component add rust-src --toolchain nightly-x86_64-unknown-linux-gnu")
    system.exec("rustup component add rust-src")

    system.exec("rustup component add llvm-tools-preview")
    system.exec(string.format("rustup default %s", RUST_VERSION))

    -- TODO: use musl-toolchain for rustc(host)
    system.exec("xvm workspace global --active false")
        system.exec("cargo install cargo-binutils")
        system.exec("cargo install bpf-linker")
    system.exec("xvm workspace global --active true")

    return true
end

function __debian_config()

    return true
end