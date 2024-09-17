use std::{
    collections::{HashMap, HashSet},
    path::{Path, PathBuf},
};

use walkdir::{Error, WalkDir};

fn main() {
    let old_generation = std::env::args()
        .nth(1)
        .expect("old generation not provided");
    let new_generation = std::env::args()
        .nth(2)
        .expect("new generation not provided");
    let home_dir = std::env::args()
        .nth(3)
        .expect("home directory not provided");

    let old_generation: PathBuf = old_generation.into();
    let old_generation = old_generation.canonicalize().ok();

    let new_generation: PathBuf = new_generation.into();
    let new_generation = new_generation
        .canonicalize()
        .expect("could not canonicalize new generation");

    // The common part of old_generation and new_generation is the nix store

    let nix_store = match old_generation.as_ref() {
        Some(old_generation) => {
            old_generation
                .ancestors()
                .zip(new_generation.ancestors())
                .find(|(old, new)| old == new)
                .expect("could not find common ancestor of old and new generation")
                .0
        }
        None => &new_generation,
    };

    println!("nix store: {:?}", nix_store);

    let home_dir: PathBuf = home_dir.into();
    let home_dir = home_dir
        .canonicalize()
        .expect("could not canonicalize home directory");

    let old_files = match old_generation.as_ref() {
        Some(old_generation) => collect_files(old_generation).expect("could not collect old files"),
        None => HashSet::new(),
    };
    let new_files = collect_files(&new_generation).expect("could not collect new files");
    let old_files_to_remove = old_files
        .difference(&new_files)
        .map(|path| home_dir.clone().join(path))
        .collect::<Vec<_>>();

    println!("old files to remove: {}", old_files_to_remove.len());

    for file in old_files_to_remove {
        if !file.exists() {
            eprintln!("file does not exist: {:?}", file);
            continue;
        }
        if !file.is_symlink() {
            eprintln!("file is not a symlink: {:?}, not replacing", file);
        }
        let target = file.read_link().expect("could not read symlink target");
        // Check if the target is in the nix store
        if !target.starts_with(nix_store) {
            eprintln!("target is not in nix store: {:?}, not replacing", target);
            continue;
        }

        // Now we know that the symlink is in the home directory and points to the old generation only
        // So delete it
        std::fs::remove_file(&file).expect("could not remove file");
    }

    let new_links_to_create = new_files
        .iter()
        .map(|path| (home_dir.clone().join(path), nix_store.join(path)))
        .collect::<HashMap<_, _>>();

    println!("new links to create: {}", new_links_to_create.len());
    for (link, target) in new_links_to_create {
        if link.exists() {
            eprintln!("link already exists: {:?}", link);
            continue;
        }
        std::fs::create_dir_all(link.parent().unwrap())
            .expect("could not create parent directories");
        std::os::unix::fs::symlink(target, link).expect("could not create symlink");
    }
}

fn collect_files<P>(generation_path: P) -> Result<HashSet<PathBuf>, Error>
where
    P: AsRef<Path>,
{
    let mut files = HashSet::new();
    let generation_path = generation_path.as_ref();
    for entry in WalkDir::new(generation_path) {
        let entry = entry?;
        if entry.file_type().is_file() {
            let newpath = entry
                .path()
                .to_path_buf()
                .strip_prefix(generation_path)
                .unwrap()
                .to_path_buf();
            files.insert(newpath);
        }
        if entry.file_type().is_symlink() && entry.path().is_file() {
            let newpath = entry
                .path()
                .to_path_buf()
                .strip_prefix(generation_path)
                .unwrap()
                .to_path_buf();
            files.insert(newpath);
        }
    }
    Ok(files)
}
