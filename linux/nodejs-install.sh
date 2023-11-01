#!/bin/bash

NODE_VERSION=v20.9.0
DISTRO=linux-x64
INSTALL_PATH=/usr/local/lib/nodejs

# Function to remove downloaded files.
cleanup_files() {
    rm "node-$NODE_VERSION-$DISTRO.tar.xz"
    rm "SHASUMS256.txt"
    rm "SHASUMS256.txt.sig"
}

# Função para remover as chaves públicas importadas
remove_imported_keys() {
    for key_id in "${key_ids[@]}"; do
      echo "yes" | gpg --batch --delete-key "$key_id"
    done
}

# Check prerequisites.
if ! command -v curl &> /dev/null; then
    echo "Error: The 'curl' command is not installed. Please install it before proceeding."
    exit 1
fi

if ! command -v gpg &> /dev/null; then
    echo "Error: The 'gpg' command is not installed. Please install it before proceeding."
    exit 1
fi

# Verify if the installation path directory exists.
if [ -d "$INSTALL_PATH" ]; then
    echo "Error: The installation path directory $INSTALL_PATH already exists."
    exit 1
fi

# Download necessary files.
curl -O "https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-$DISTRO.tar.xz"
curl -O "https://nodejs.org/dist/$NODE_VERSION/SHASUMS256.txt"
curl -O "https://nodejs.org/dist/$NODE_VERSION/SHASUMS256.txt.sig"

# Import public keys
declare -a key_ids=(
    4ED778F539E3634C779C87C6D7062848A1AB005C
    141F07595B7B3FFE74309A937405533BE57C7D57
    74F12602B6F1C4E913FAA37AD3A89613643B6201
    DD792F5973C6DE52C432CBDAC77ABFA00DDBF2B7
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8
    890C08DB8579162FEE0DF9DB8BEAB4DFCF555EF4
    C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C
    108F52B48DB57BB0CC439B2997B01419BD92F80A
    A363A499291CBBC940DD62E41F10027AF002F8B0
)

for key_id in "${key_ids[@]}"; do
    if gpg --list-keys | grep -q "$key_id"; then
        echo "Key $key_id is already imported."
    else
        gpg --keyserver hkps://keys.openpgp.org --recv-keys "$key_id"
    fi
done

# Verify the signature.
if gpg --verify SHASUMS256.txt.sig SHASUMS256.txt; then
    # Verify the hash.
    if grep "node-$NODE_VERSION-$DISTRO.tar.xz" SHASUMS256.txt | sha256sum -c -; then
        # If the signature and hash are correct, install Node.js.
        sudo mkdir -p "$INSTALL_PATH"
        sudo tar -xJf "node-$NODE_VERSION-$DISTRO.tar.xz" -C "$INSTALL_PATH"
        echo "export PATH=$INSTALL_PATH/node-$NODE_VERSION-$DISTRO/bin:$PATH" >> ~/.bash_profile
        echo "Node.js installed successfully."
        remove_imported_keys
        cleanup_files
    else
        echo "Error: The hash does not match."
        remove_imported_keys
        cleanup_files
    fi
    elif [ $? -eq 2 ]; then
    echo "Error: Verification of signature or integrity check failed. Removing downloaded files and imported keys."
    remove_imported_keys
    cleanup_files
else
    echo "Error: The signature is not valid. Removing downloaded files and imported keys."
    remove_imported_keys
    cleanup_files
fi

