use std::{env, os::unix::fs::PermissionsExt, path::{Component, Path, PathBuf}};

use serde::Deserialize;

#[derive(Debug, PartialEq, Eq)]
enum Executable {
    Yes,
    No,
    Inherit,
}

impl<'de> Deserialize<'de> for Executable {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        deserializer.deserialize_any(ExecutableVisitor)
    }
}

struct ExecutableVisitor;

impl <'de> serde::de::Visitor<'de> for ExecutableVisitor {
    type Value = Executable;

    fn expecting(&self, formatter: &mut std::fmt::Formatter) -> std::fmt::Result {
        formatter.write_str("a string")
    }

    fn visit_str<E>(self, value: &str) -> Result<Self::Value, E>
    where
        E: serde::de::Error,
    {
        match value {
            "inherit" => Ok(Executable::Inherit),
            _ => Err(serde::de::Error::invalid_value(serde::de::Unexpected::Str(value), &self)),
        }
    }

    fn visit_unit<E>(self) -> Result<Self::Value, E>
        where
            E: serde::de::Error, {
        Ok(Executable::Inherit)
    }

    fn visit_bool<E>(self, v: bool) -> Result<Self::Value, E>
        where
            E: serde::de::Error, {
        match v {
            true => Ok(Executable::Yes),
            false => Ok(Executable::No),
        }
    }
}


#[derive(Debug, Deserialize)]
struct NixFile {
    source: String,
    target: String,
    executable: Executable,
}


fn main() {
    // Parse the json in argv[1] using merde
    let inp = env::args().nth(1).expect("No input file given");
    let out = env::var("out").expect("No output directory given");
    let nix_files: Vec<NixFile> = serde_json::from_str(&inp).expect("Invalid JSON");

    let out: PathBuf = out.into();
    std::fs::create_dir_all(&out).expect("Could not create output directory");
    let out = out.canonicalize().expect("Invalid output directory (could not be canonicalized)");

    for nix_file in nix_files {
        // Log an error if the target path already exists
        let target = out.join(&nix_file.target);
        if target.exists() {
            eprintln!("{} already exists", target.display());
            continue;
        }

        // Get the real path of the target
        let full_target = normalize_path(&out.join(&nix_file.target));

        // Error if the target is not a child of the out directory
        if !full_target.starts_with(&out) {
            eprintln!("{} is not a child of {}", target.display(), out.display());
            continue;
        }

        // Make any parent directories of the target
        std::fs::create_dir_all(full_target.parent().expect("Could not get parent of target path")).expect("Could not create parent directories");

        let source = PathBuf::from(&nix_file.source);

        // If the source is a directory, simply link it
        if source.is_dir() {
            std::os::unix::fs::symlink(&source, &full_target).expect("Could not link directory");
            continue;
        } else {
            // Check if the source file has the executable bit set
            let source_executable = source.metadata().expect("Could not get file permissions").permissions().mode() & 0o111 != 0;
            if source_executable && nix_file.executable == Executable::Yes {
                // We can link it
                std::os::unix::fs::symlink(&source, &full_target).expect("Could not link executable file");
                continue;
            }
            if !source_executable && nix_file.executable == Executable::No {
                // We can link it
                std::os::unix::fs::symlink(&source, &full_target).expect("Could not link non-executable file");
                continue;
            }
            if nix_file.executable == Executable::Inherit {
                // We can link it
                std::os::unix::fs::symlink(&source, &full_target).expect("Could not link file");
                continue;
            }

            // We should copy it
            std::fs::copy(&source, &full_target).expect("Could not copy file");
            // And set the executable bit if needed
            match nix_file.executable {
                Executable::Yes => {
                    let mut perms = full_target.metadata().expect("Could not get target permissions").permissions();
                    perms.set_mode(0o755);
                    std::fs::set_permissions(&full_target, perms).expect("Could not set target permissions");
                }
                Executable::No => {
                    let mut perms = full_target.metadata().expect("Could not get target permissions").permissions();
                    perms.set_mode(0o644);
                    std::fs::set_permissions(&full_target, perms).expect("Could not set target permissions");
                }
                Executable::Inherit => {}
            }
        }
    }
}

pub fn normalize_path(path: &Path) -> PathBuf {
    let mut components = path.components().peekable();
    let mut ret = if let Some(c @ Component::Prefix(..)) = components.peek().cloned() {
        components.next();
        PathBuf::from(c.as_os_str())
    } else {
        PathBuf::new()
    };

    for component in components {
        match component {
            Component::Prefix(..) => unreachable!(),
            Component::RootDir => {
                ret.push(component.as_os_str());
            }
            Component::CurDir => {}
            Component::ParentDir => {
                ret.pop();
            }
            Component::Normal(c) => {
                ret.push(c);
            }
        }
    }
    ret
}
