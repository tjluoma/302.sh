#!/bin/zsh -f
# create a 302 redirect
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2013-03-04

	# This could also be Dropbox or something else
SYNC_APP="BitTorrent Sync"

	# this is the domain to use with the short URLs
YOUR_DOMAIN='luo.ma'


####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		You should not have to change anything below this line
#


NAME="$0:t"

zmodload zsh/datetime

function timestamp { strftime "%Y-%m-%d--%H.%M.%S" "$EPOCHSECONDS" }

function die
{
	echo "$NAME: $@"
	exit 1
}

pgrep -q "$SYNC_APP"

if [ "$?" = "1" ]
then
		# Launch the app
		# Hide the app
		# note that hiding Dropbox isn't necessary because it's a menu bar app
	command open -g --hide -a "$SYNC_APP"

	if [[ "$SYNC_APP" == "BitTorrent Sync" ]]
	then
			# BTS does not respect either --background or --hide
			# so we have to hide it 'manually'
		sleep 2
		osascript -e 'tell application "System Events" to set visible of process "$SYNC_APP" to false'
	fi
fi

if ((! $+commands[growlnotify] ))
then
	echo "$NAME: growlnotify is required but not found in $PATH"
	open 'http://growl.info/downloads#generaldownloads'
	exit 1
fi

if [[ ! -e '/Applications/Growl.app' ]]
then
	echo "$NAME: Growl.app is not installed"
	open 'macappstore://itunes.apple.com/us/app/growl/id467939042?mt=12'
	exit 1
fi

	# if Growl is not running, launch it
pgrep -q -x Growl || open -a Growl

	# Change this to wherever the .htaccess file is on your computer
HTACCESS="${HOME}/Sites/${YOUR_DOMAIN}/.htaccess"

[[ ! -e "$HTACCESS" ]] && die "HTACCESS not found at $HTACCESS"

if [ "$#" = "2" ]
then
	# if there are 2 args

			# if the 1st arg starts with "http" then assume that it is the URL; otherwise assume it is the slug
		GUESS=$(echo "$1" | colrm 5)

		if [ "$GUESS" = "http" ]
		then
				URL="$1"
				SLUG="$2"
		else
				SLUG="$1"
				URL="$2"
		fi

elif [ "$#" = "1" ]
then
	# if there is one arg

		GUESS=$(echo "$1" | colrm 5)

		if [ "$GUESS" = "http" ]
		then
				URL="$1"

				read "?What slug do you want to use for '$URL'? " SLUG
		else
				SLUG="$1"

				read "?What URL do you want to use for '$SLUG'? " URL
		fi
else
	# if there is some other number of args, don't try to guess,
	# just ask the user what they are trying to do

		read "?What is the full URL? " URL

		read "?What slug do you want to use for '$URL'? " SLUG
fi

	# Check to see if the new $SLUG (original or lowercase) already exists in $HTACCESS
	# We don't want to end up with multiple SLUGs pointing to different URLs. That would be bad.
egrep '^redirect ' "$HTACCESS" | awk '{print $3}' | fgrep -q "/$SLUG" 	&& die "$SLUG already exists in $HTACCESS"
egrep '^redirect ' "$HTACCESS" | awk '{print $3}' | fgrep -q "/$SLUG:l"	&& die "$SLUG:l (lowercase) already exists in $HTACCESS"

	# get the character count of the slug
	# since the purpose (for me) of making a slug is usually to post it to twitter
	# I need to make sure that Twitter isn't going to truncate it
	# which would sort of defeat the purpose
SLUG_WC=$(echo -n "$SLUG" | wc -c | tr -dc '[0-9]')

if [ "$SLUG_WC" -gt "15" ]
then
		# Show the user what the Twitter-truncated URL would be
	TRUNCATED_SLUG=$(echo "$SLUG" | colrm 15)

		# Note: We don't actually _do_ anything with $ANSWER
		# it's just a placeholder. If they press control+c it will cancel the script
		# anything else will continue
	read "?$NAME: Twitter will truncate '$SLUG' to '$TRUNCATED_SLUG'. Use anyway? [Press 'Control + C' for no] " ANSWER

else
		# if the character count is 15 or under, tell user we are OK
	echo "	$NAME [info] SLUG_WC is $SLUG_WC (must be under 15 to avoid Twitter truncation)"
fi

	# here is where we actually add the redirect to the .htaccess file
echo 		"redirect 302 /$SLUG			$URL" >> "$HTACCESS"

	# if -- somehow -- that command failed, bail immediately
[[ "$?" != "0" ]] && die "failed to add $SLUG to $HTACCESS (\$EXIT = $EXIT)"

if [ "$SLUG:l" != "$SLUG" ]
then
			# if the slug is not lowercase already, make a lowercase equivalent
		echo 	"redirect 302 /$SLUG:l			$URL" >>  "$HTACCESS"

			# if -- somehow -- that command failed, bail immediately
		[[ "$?" != "0" ]] && die "failed to add $SLUG:l to $HTACCESS (\$EXIT = $EXIT)"
fi

	# record start time
START_TIME="$EPOCHSECONDS"

	# add an extra line return just for readability in the HTACCESS
echo "\n" >> "$HTACCESS"

	# show the user the end of the HTACCESS file so they can sanity check it
tail -5 "$HTACCESS"

	# put the SLUG version of the URL on the pasteboard
echo -n "http://${YOUR_DOMAIN}/$SLUG" | pbcopy

echo "	$NAME: http://${YOUR_DOMAIN}/$SLUG is now on pasteboard ($HTACCESS)"

	# Now start waiting for  the URL to actually come alive on the Internet
	# aka wait for the sync to complete
	# NOTE: this assumes that you already have $HTACCESS syncing somehow,
	# whether that is BitTorrent Sync (which I am using) or Dropbox or something else
growlnotify \
	--sticky \
	--appIcon "$SYNC_APP" \
	--identifier "$NAME" \
	--message "Waiting for ${YOUR_DOMAIN}/$SLUG to come alive" \
	--title "$NAME"

	# function to check the URL's HTTP status
function get_status { STATUS=`curl -s --head "http://${YOUR_DOMAIN}/$SLUG" | awk -F' ' '/^HTTP/{print $2}'` }

	# run the function
get_status

	# until the status is what we want it to be, wait 5 seconds, then check again
while [ "$STATUS" != "302" ]
do
	sleep 5
	get_status
done

	# record the finish time
END_TIME="$EPOCHSECONDS"

	# calculate the difference in seconds between start time and end time
WAIT_TIME=$(($END_TIME - $START_TIME))

	# play a sound to tell user that URL is active
afplay /System/Library/Sounds/Glass.aiff

growlnotify \
	--appIcon "$SYNC_APP"  \
	--identifier "$NAME"  \
	--url "http://${YOUR_DOMAIN}/$SLUG" \
	--message "Sync took $WAIT_TIME seconds"  \
	--title "${YOUR_DOMAIN}/$SLUG is alive
(Click to open)"

exit 0

#
#EOF
