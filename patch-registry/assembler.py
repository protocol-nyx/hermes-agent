
import subprocess
import os
import yaml
import sys
import shutil

def run_cmd(cmd, cwd=None):
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True, cwd=cwd)
    return res

def assemble():
    print("--- Starting Assembly ---")
    
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)
    
    with open("manifest.yaml", "r") as f:
        manifest = yaml.safe_load(f)
    
    base_tag = manifest['meta']['base_tag']
    groups = manifest['groups']
    
    build_dir = "build_runtime"
    if os.path.exists(build_dir):
        shutil.rmtree(build_dir)
        
    print(f"Cloning base tag: {base_tag}...")
    run_cmd(f"git clone --depth 1 --branch {base_tag} https://github.com/NousResearch/hermes-agent.git {build_dir}")
    
    overall_success = True
    for group in groups:
        group_name = group['name']
        patches = group['patches']
        print(f"\nProcessing Group: {group_name}...")
        
        group_failed = False
        for p in patches:
            patch_path = os.path.join(script_dir, p['file'])
            print(f" Applying {p['id']}...")
            # Essential: quotes around the patch path to handle spaces in the vault path
            res = run_cmd(f'git apply --3way "{patch_path}"', cwd=build_dir)
            
            if res.returncode != 0:
                print(f" [!] Patch {p['id']} FAILED: {res.stderr}")
                group_failed = True
                overall_success = False
            else:
                print(f" [+] Patch {p['id']} applied.")
        
        if group_failed:
            print(f" Group {group_name} marked as BROKEN.")
        else:
            print(f" Group {group_name} READY.")

    print("\nInjecting custom tests...")
    custom_tests_src = os.path.join(script_dir, "tests/nyx_custom")
    custom_tests_dest = os.path.join(build_dir, "tests/nyx_custom")
    if os.path.exists(custom_tests_src):
        shutil.copytree(custom_tests_src, custom_tests_dest, dirs_exist_ok=True)

    print("\nPushing to integration branch...")
    sync_cmds = [
        f"git remote add nyx-origin https://x-access-token:$GITHUB_TOKEN_NYX@github.com/protocol-nyx/hermes-agent.git",
        "git checkout -b integration",
        "git push nyx-origin integration --force"
    ]
    
    for cmd in sync_cmds:
        res = run_cmd(cmd, cwd=build_dir)
        if res.returncode != 0:
            print(f"Push failed: {res.stderr}")
            return False

    print("\n--- Assembly Complete: Integration branch updated ---")
    return overall_success

if __name__ == "__main__":
    if not assemble():
        sys.exit(1)
