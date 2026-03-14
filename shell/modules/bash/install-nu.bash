set -e

echo "Installing Nushell..."
sudo pacman -S --noconfirm nushell

NU_PATH=$(which nu)

echo "Adding $NU_PATH to /etc/shells..."
if ! grep -qxF "$NU_PATH" /etc/shells; then
    echo "$NU_PATH" | sudo tee -a /etc/shells
fi

echo "Changing default shell to Nushell..."
chsh -s "$NU_PATH"

echo "Done. Re-login or start a new session for the change to take effect."
