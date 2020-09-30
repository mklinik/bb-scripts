if [ ! -f $MYDIR/config.sh ]; then
    echo "Expecting configuration in config.sh. Refer to the template file config_template.sh"
    exit 1
fi

# This will input/source the contents of the config.sh file, which
# will not be tracked by git.

. $MYDIR/config.sh
