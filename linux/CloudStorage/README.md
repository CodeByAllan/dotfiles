
# Rclone Mount Cloud Service Config Script

Script that helps in setting up cloud storage such as Google Drive and OneDrive



## Documentation

1. Install Rclone

- fedora 
```
sudo dnf install rclone -y
```
- debian / ubuntu
```
sudo apt installl rclone -y
```
- arch
```
sudo pacman -S --noconfirm rclone
```

2. Download the script by executing the following command:

```
git clone "https://github.com/CodeByAllan/dotfiles.git"

```

3. Execute the script:

```
cd dotfiles/linux/rclone
chmod +x Cloud-Storage*
./Cloud-StorageConfig.sh [type_cloud] [remote_name]
```

## Authors

- [@CodeByAllan](https://www.github.com/CodeByAllan)
