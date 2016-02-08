from fabric.api import cd, env, lcd, local, run, sudo
import os

env.use_ssh_config = True

REPO_NAME = 'traildb-d'
S3_RELEASE_PATH = "s3://adroll-data-science/{dest}/{repo}/{version}/{tarball}"

def package(version):
    ver = version.replace(".", "_")
    release_folder = ver
    local("mkdir %s" % release_folder)
    local("git clone --recursive git@github.com:SemanticSugar/%s.git %s"
          % (REPO_NAME, release_folder))
    with lcd(release_folder):
        local("git fetch origin")
        local("git checkout %s" % version)
        # Add git SHA1 file
        local("echo %s > version.txt" % ver)
        local("git rev-parse HEAD >> version.txt")

        # Remove useless parts
        local("rm -rf .git*")
        local("rm -rf prod_conf README.md")
    tarball = "%s.tar.gz" % release_folder
    local("tar czf %s %s" % (tarball, release_folder))
    local("rm -r %s" % release_folder)
    return tarball

def push_package_to_s3(tarball, version, dest):
    """
    /!!!/ STOP HERE /!!!/
    DO NOT USE THIS METHOD, YOU FOOL!
    Ask Benoit before using this method, or burn in hell forever!
    """
    version = version.replace(".", "_")
    s3_address = S3_RELEASE_PATH.format(
        dest=dest,
        repo=REPO_NAME,
        version=version,
        tarball=tarball,
    )
    local("aws s3 cp --region us-west-2 %s %s" % (tarball, s3_address))
    local("rm %s" % tarball)


def package_and_s3_deploy(version, dest="dev_releases"):
    """
    /!!!/ STOP HERE /!!!/
    DO NOT USE THIS METHOD, YOU FOOL!
    Ask Benoit before using this method, or burn in hell forever!
    """
    if dest not in ["dev_releases", "releases"]:
        raise Exception("Invalid destination on s3. Has to be either "
            "`dev_releases` or `releases`")
    tarball = package(version)
    push_package_to_s3(tarball, version, dest)
