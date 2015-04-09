#!/bin/bash

USAGE="$0 COMMAND ARGUMENTS

Commands:
- clone REPOSITORY BRANCH [DIR]     git clone the specified branch; or master if the branch is not available -- optionally provide location
- checkout WORK_TREE BRANCH         check out the specified remote branch as a local branch or master if the branch is not available"

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
		git clone -b $branch $repo $target >/dev/null 2>&1
		ec=$?
		if [ $ec -ne 0 ]; then
			echo "Cloning failed (code $ec). Attempting to clone master of repository $repo..."
			git clone $repo >/dev/null 2>&1
			ec=$?
			if [ $ec -ne 0 ]; then
				echo "Cloning failed (code $ec). No clone was created."
				exit 4
			fi
			exit 0
		fi
		exit 0
		;;
	"checkout")
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

		echo "Changing to $target..."
		cd $target
		echo "Resetting state..."
		git checkout master >/dev/null 2>&1
		ec=$?
		if [ $ec -ne 0 ]; then
			echo "Reset failed (code $ec). Aborting."
			cd - >/dev/null 2>&1
			exit 6
		fi

		echo "Checking out..."
		git branch -a | grep " $branch\$" >/dev/null 2>&1
		if [ $? -eq 0 ]; then
			echo "Checking out existing branch $branch..."
			git checkout $branch >/dev/null 2>&1
			ec=$?
			if [ $ec -ne 0 ]; then
				echo "Checkout failed (code $ec). Aborting."
				cd - >/dev/null 2>&1
				exit 4
			fi
			cd - >/dev/null
			exit 0
		else
			git branch -a | grep " remotes/origin/$branch" >/dev/null 2>&1
			if [ $? -eq 0 ]; then
				echo "Setting up local branch $branch..."
				git branch $branch >/dev/null 2>&1
				ec=$?
				if [ $ec -ne 0 ]; then
					echo "Branch setup failed (code $ec). Aborting."
					cd - >/dev/null
					exit 4
				fi
				echo "Setting up branch tracking..."
				git branch --set-upstream-to=remotes/origin/$branch $branch >/dev/null 2>&1
				ec=$?
				if [ $ec -ne 0 ]; then
					echo "Branch setup failed (code $ec). Aborting."
					cd - >/dev/null
					exit 4
				fi
				echo "Checking out newly setup branch $branch..."
				git checkout $branch >/dev/null 2>&1
				ec=$?
				if [ $ec -ne 0 ]; then
					echo "Checkout failed (code $ec). Aborting."
					cd - >/dev/null 2>&1
					exit 4
				fi
				cd - >/dev/null
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
