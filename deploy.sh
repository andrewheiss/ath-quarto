REMOTE_HOST="cloud"
REMOTE_DIR="~/sites/andrewheiss.com/public_html"
REMOTE_DEST=$REMOTE_HOST:$REMOTE_DIR

echo "Uploading new changes to remote server..."
echo
rsync -crvP --exclude='.DS_Store' --exclude='.Rproj.user/' --delete _site/ $REMOTE_DEST
