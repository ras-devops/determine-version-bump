#!/bin/bash

# Get the latest tag for the current commit if it exists
latest_tag=$(git describe --exact-match --tags 2>/dev/null)

if [ -z "$latest_tag" ]; then
    echo "No exact match tag found for the current commit."
    # If there is no tag for the current commit, get the latest tag for the branch
    latest_tag=$(git describe --tags --abbrev=0)
    echo "Latest tag for the branch: $latest_tag"
    # Set the variable to indicate the need to bump the version
    bump_version=true
else
    echo "Exact match tag found for the current commit: $latest_tag"
    # Set the variable to indicate no need to bump the version
    bump_version=false
fi

echo "Bump version required: $bump_version"

version=$latest_tag
labels=$(cat $2)

prerelease_suffix=$(echo $version | awk -F- '{print $2}' | awk -F. '{print $1}')
echo "prerelease_suffix $prerelease_suffix"

if [[ $labels == *"bump:major"* ]] && [[ $labels == *"pre:rc"* ]]; then
  bump_type="major_rc"
elif [[ $labels == *"bump:major"* ]] && [[ $labels == *"pre:beta"* ]]; then
  bump_type="major_beta"
elif [[ $labels == *"bump:major"* ]] && [[ $labels == *"pre:alpha"* ]]; then
  bump_type="major_alpha"
elif [[ $labels == *"bump:minor"* ]] && [[ $labels == *"pre:rc"* ]]; then
  bump_type="minor_rc"
elif [[ $labels == *"bump:minor"* ]] && [[ $labels == *"pre:beta"* ]]; then
  bump_type="minor_beta"
elif [[ $labels == *"bump:minor"* ]] && [[ $labels == *"pre:alpha"* ]]; then
  bump_type="minor_alpha"
elif [[ $labels == *"bump:patch"* ]] && [[ $labels == *"pre:rc"* ]]; then
  bump_type="patch_rc"
elif [[ $labels == *"bump:patch"* ]] && [[ $labels == *"pre:beta"* ]]; then
  bump_type="patch_beta"
elif [[ $labels == *"bump:patch"* ]] && [[ $labels == *"pre:alpha"* ]]; then
  bump_type="patch_alpha"
elif [[ $labels == *"bump:major"* ]]; then
  bump_type="major"
elif [[ $labels == *"bump:minor"* ]]; then
  bump_type="minor"
elif [[ $labels == *"bump:patch"* ]]; then
  bump_type="patch"
elif [[ $labels == *"bump:release"* ]]; then
  bump_type="release"
elif [[ $labels == *"pre:rc"* ]] && [[ -z $prerelease_suffix ]]; then
  bump_type="rc"
elif [[ $labels == *"pre:beta"* ]] && [[ -z $prerelease_suffix ]]; then
  bump_type="beta"
elif [[ $labels == *"pre:alpha"* ]] && [[ -z $prerelease_suffix ]]; then
  bump_type="alpha"
elif [[ $labels == *"pre:rc"* ]] && [[ -n $prerelease_suffix ]]; then
  bump_type="rc_prerelease_suffix"
elif [[ $labels == *"pre:beta"* ]] && [[ -n $prerelease_suffix ]]; then
  bump_type="beta_prerelease_suffix"
elif [[ $labels == *"pre:alpha"* ]] && [[ -n $prerelease_suffix ]]; then
  bump_type="alpha_prerelease_suffix"
elif [[ $labels != *"pre:"* ]] && [[ $labels != *"bump:"* ]] && [[ -z $prerelease_suffix ]]; then
  bump_type="without_labels_prerelease_suffix"
elif [[ $labels != *"pre:"* ]] && [[ $labels != *"bump:"* ]]; then
  bump_type="without_labels"
else
  echo "No version bump labels found. Bumping build number."
  bump_type="build"
fi

echo $bump_type

generate_semver_command() {
  case $bump_type in
  "release")
    if [[ -z $prerelease_suffix ]]; then
      echo "semver bump patch $version"
    else
      echo "semver bump release $version"
    fi
    ;;
  "major_rc")
    first_major_rc=$(semver bump major $version)
    echo "semver bump prerel rc $first_major_rc"
    ;;
  "major_beta")
    first_major_beta=$(semver bump major $version)
    echo "semver bump prerel beta $first_major_beta"
    ;;
  "major_alpha")
    first_major_alpha=$(semver bump major $version)
    echo "semver bump prerel alpha $first_major_alpha"
    ;;
  "minor_rc")
    first_minor_rc=$(semver bump minor $version)
    echo "semver bump prerel rc $first_minor_rc"
    ;;
  "minor_beta")
    first_minor_beta=$(semver bump minor $version)
    echo "semver bump prerel beta $first_minor_beta"
    ;;
  "minor_alpha")
    first_minor_alpha=$(semver bump minor $version)
    echo "semver bump prerel alpha $first_minor_alpha"
    ;;
  "patch_rc")
    first_patch_rc=$(semver bump patch $version)
    echo "semver bump prerel rc $first_patch_rc"
    ;;
  "patch_beta")
    first_patch_beta=$(semver bump patch $version)
    echo "semver bump prerel beta $first_patch_beta"
    ;;
  "patch_alpha")
    first_patch_alpha=$(semver bump patch $version)
    echo "semver bump prerel alpha $first_patch_alpha"
    ;;
  "major")
    echo "semver bump major $version"
    ;;
  "minor")
    echo "semver bump minor $version"
    ;;
  "patch")
    echo "semver bump patch $version"
    ;;
  "rc")
    first_rc=$(semver bump patch $version)
    echo "semver bump prerel rc $first_rc"
    ;;
  "beta")
    first_beta=$(semver bump patch $version)
    echo "semver bump prerel beta $first_beta"
    ;;
  "alpha")
    first_alpha=$(semver bump patch $version)
    echo "semver bump prerel alpha $first_alpha"
    ;;
  "rc_prerelease_suffix")
    if [[ $prerelease_suffix == *"beta"* ]] || [[ $prerelease_suffix == *"alpha"* ]]; then
      echo "semver bump prerel rc $version"
    elif [[ $prerelease_suffix == *"rc"* ]]; then
      echo "semver bump prerel $version"
    fi
    ;;
  "beta_prerelease_suffix")
    if [[ $prerelease_suffix == *"beta"* ]] || [[ $prerelease_suffix == *"rc"* ]]; then
      echo "semver bump prerel $version"
    else
      echo "semver bump prerel beta $version"
    fi
    ;;
  "alpha_prerelease_suffix")
    if [[ $prerelease_suffix == *"alpha"* ]] || [[ $prerelease_suffix == *"rc"* ]] || [[ $prerelease_suffix == *"beta"* ]]; then
      echo "semver bump prerel $version"
    else
      echo "semver bump prerel alpha $version"
    fi
    ;;
  "without_labels")
    echo "semver bump prerel $version"
    ;;
  "without_labels_prerelease_suffix")
    first_without_labels_prerelease_suffix=$(semver bump patch $version)
    echo "semver bump prerel alpha $first_without_labels_prerelease_suffix"
    ;;
  *)
    echo "Invalid bump type"
    exit 1
    ;;
  esac
}
# Function to extract the prerelease label from the version
get_prerelease_label() {
  echo "$1" | awk -F- '{print $2}' | awk -F. '{print $1}'
}

# Generate and execute the first semver command
first_command=$(generate_semver_command "$labels" "$version")
new_version=v$(eval "$first_command")
sha=$(git rev-parse HEAD)
sha_short=$(git rev-parse --short HEAD)

echo "sha=$(git rev-parse HEAD)"
echo "sha_short=$(git rev-parse --short HEAD)"
echo "current_tag_or_commit=$(git describe --exact-match --tags 2> /dev/null || git rev-parse --short HEAD)"
echo "Previous Version: $version"
echo "Labels attached to the Pull Request: $labels"
echo "An Actual Tag or a commit for a state of this repository: $current_tag_or_commit"

# Additional actions if bump_version is true
if [ "$bump_version" = true ] && ([ "$GITHUB_REF" = "refs/heads/main" ] || [ "$GITHUB_REF" = "refs/heads/next" ]); then
    echo "New Version: $new_version"
    echo "new_version=$new_version" >> $GITHUB_OUTPUT
elif [ "$bump_version" = true ] && ([ "$GITHUB_REF" != "refs/heads/main" ] || [ "$GITHUB_REF" != "refs/heads/next" ]); then
    echo "New Version: $version-$sha_short Because it's not main/next branch "
    echo "new_version=$version-$sha_short" >> $GITHUB_OUTPUT
else
    echo "Possible New Version: $new_version"
    echo "new_version=$version" >> $GITHUB_OUTPUT
fi
echo "sha=$(git rev-parse HEAD)" >> $GITHUB_OUTPUT
echo "sha_short=$(git rev-parse --short HEAD)" >> $GITHUB_OUTPUT
echo "current_version=$current_tag_or_commit" >> $GITHUB_OUTPUT
echo "previous_version=$version" >> $GITHUB_OUTPUT
