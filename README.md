# HDD burn-in test

A script to test your new hdd for damage.

## Usage

**Warning** this script will destroy all data on the drive!

Manual execution:
```shell
curl https://raw.githubusercontent.com/Sirius708/hdd-burn-in-test/main/burn-in-test.sh
chmod +x burn-in-test.sh
./burn-in-test.sh /dev/sdX
```

Execute from download:
```shell
curl https://raw.githubusercontent.com/Sirius708/hdd-burn-in-test/main/burn-in-test.sh | bash -s -- /dev/sdX
```

Use something like tmux or screen to run this script for multiple drives in parallel.
