#!/bin/bash

USAGE="$0 COMMAND ARGUMENTS

Commands:
- clone REPOSITORY BRANCH [DIR]     git clone the specified branch; or master if the branch is not available -- optionally provide location
- checkout WORK_TREE BRANCH         check out the specified remote branch as a local branch or master if the branch is not available
- force-checkout WORK_TREE BRANCH   same as checkout, except a reset --hard will be executed (this might potentially destroy your changes if used incorrectly!)"

if [ $# -eq 0 ]; then
	echo "$USAGE"
	exit 1
fi

cmd=$1

case $cmd in
	"clone")
		repo=$2
		branch=$3
		target=$4
		if [ -z "$repo" -o -z "$branch" ]; then
			echo "$USAGE"
			exit 2
		fi

		echo "Cloning branch '$branch' of repository $repo..."
		echo git clone -b $branch $repo $target
		git clone -b $branch $repo $target
		ec=$?
		if [ $ec -ne 0 ]; then
			echo "Cloning failed (code $ec). Attempting to clone master of repository $repo..."
			echo git clone $repo $target
			git clone $repo $target
			ec=$?
			if [ $ec -ne 0 ]; then
				echo "Cloning failed (code $ec). No clone was created."
				exit 4
			fi
			exit 0
		fi
		exit 0
		;;
	"checkout"|"force-checkout")
		target=$2
		branch=$3
		if [ -z "$target" -o -z "$branch" ]; then
			echo "$USAGE"
			exit 2
		fi

		if [ ! -d $target ]; then
			echo "Checkout failed. Target is not a repository."
			exit 5
		fi

		if [ "$target" != "." ]; then
			echo "Changing to $target..."
			cd $target
		fi

		if [ "$cmd" == "force-checkout" ]; then
			git reset --hard
		fi

		echo "Attempting to return to master..."

		echo git checkout master
		git checkout master
		ec=$?
		if [ $ec -ne 0 ]; then
			echo "Reset failed (code $ec). Aborting."
			cd - >/dev/null 2>&1
			exit 6
		fi

		echo "Checking out..."
		echo git branch -a | grep " $branch\$"
		git branch -a | grep " $branch\$"
		if [ $? -eq 0 ]; then
			echo "Checking out existing branch $branch..."
			echo git checkout $branch
			git checkout $branch
			ec=$?
			if [ $ec -ne 0 ]; then
				echo "Checkout failed (code $ec). Aborting."
				cd - >/dev/null 2>&1
				exit 4
			fi
			cd - >/dev/null 2>&1
			exit 0
		else
			echo git branch -a | grep " remotes/origin/$branch\$"
			git branch -a | grep " remotes/origin/$branch\$"
			if [ $? -eq 0 ]; then
				echo "Setting up local branch $branch..."
				echo git branch $branch
				git branch $branch
				ec=$?
				if [ $ec -ne 0 ]; then
					echo "Branch setup failed (code $ec). Aborting."
					cd - >/dev/null 2>&1
					exit 4
				fi
				echo "Setting up branch tracking..."
				echo git branch --set-upstream-to=remotes/origin/$branch $branch
				git branch --set-upstream-to=remotes/origin/$branch $branch
				ec=$?
				if [ $ec -ne 0 ]; then
					echo "Branch setup failed (code $ec). Aborting."
					cd - >/dev/null 2>&1
					exit 4
				fi
				echo "Checking out newly setup branch $branch..."
				echo git checkout $branch
				git checkout $branch
				ec=$?
				if [ $ec -ne 0 ]; then
					echo "Checkout failed (code $ec). Aborting."
					cd - >/dev/null 2>&1
					exit 4
				fi
				cd - >/dev/null 2>&1
				exit 0
			else
				echo "Target branch does not exist locally or remotely. Checking out master."
				cd - >/dev/null 2>&1
				exit 0
			fi
		fi
		;;

	*)
		echo "$USAGE"
		exit 3
		;;
esac
