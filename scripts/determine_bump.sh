#!/bin/bash
current_version=$1
labels=$(cat $2)
validate_version() {
  local version="$1"
  regex="^v?([0-9]+\.){2}[0-9]+(-[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*)?(\+[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*)?$"

  if [[ $version =~ $regex ]]; then
    echo "Valid version: $version"
  else
    echo "Invalid version: $version"
    exit 1
  fi
}
:
validate_version "$current_version"
# Determine the bump type (major, minor, patch, or build)
if [[ $labels == *"bump:major"* ]]; then
  bump_type="major"
elif [[ $labels == *"bump:minor"* ]]; then
  bump_type="minor"
elif [[ $labels == *"bump:patch"* ]]; then
  bump_type="patch"
else
  echo "No version bump labels found. Bumping build number."
  bump_type="build"
fi

# Determine prerelease type and build number
prerelease_label=$(echo $current_version | awk -F- '{print $2}' | awk -F. '{print $1}')
build_number=$(echo $current_version | sed -n 's/.*-'"$prerelease_label"'\.\([0-9]\{1,\}\)/\1/p')

echo "prerelease_label: $prerelease_label"
echo "build_number: $build_number"

# If prerelease labels are present, prioritize them
if [ -n "$labels" ]; then
  if ([[ $bump_type == "major" || $bump_type == "minor" || $bump_type == "patch" ]]) && [[ $labels == *"pre:alpha"* ]]; then
    prerelease_type="alpha"
  elif ([[ $bump_type == "major" || $bump_type == "minor" || $bump_type == "patch" ]]) && [[ $labels == *"pre:beta"* ]]; then
    prerelease_type="beta"
  elif ([[ $bump_type == "major" || $bump_type == "minor" || $bump_type == "patch" ]]) && [[ $labels == *"pre:demo"* ]]; then
    prerelease_type="demo"
  elif [[ $labels == *"pre:demo"* ]]; then
    prerelease_type="demo"
  elif [[ $labels == *"pre:beta"* ]] && [[ $prerelease_label == "demo" ]]; then
    prerelease_type="demo"
  elif [[ $labels == *"pre:alpha"* ]] && [[ $prerelease_label == "demo" ]]; then
    prerelease_type="demo"
  elif [[ $labels == *"pre:alpha"* ]] && [[ $prerelease_label == "beta" ]]; then
    prerelease_type="beta"
  elif [[ $labels == *"pre:beta"* ]] && ([[ $prerelease_label == "beta" ]] || [[ -z $prerelease_label ]]); then
    prerelease_type="beta"
  elif [[ $labels == *"pre:alpha"* ]] && [[ $prerelease_label != *"pre:beta"* ]] && [[ $prerelease_label != *"pre:demo"* ]]; then
    prerelease_type="alpha"
  fi
fi

echo "prerelease_type $prerelease_type"

###############################################
if [[ $bump_type == "major" ]] && [[ "$prerelease_type" == "alpha" ]]; then
  bump_type="major_alpha"
elif [[ $bump_type == "minor" ]] && [[ "$prerelease_type" == "alpha" ]]; then
  bump_type="minor_alpha"
elif [[ $bump_type == "patch" ]] && [[ "$prerelease_type" == "alpha" ]]; then
  bump_type="patch_alpha"
elif [[ $bump_type == "major" ]] && [[ "$prerelease_type" == "beta" ]]; then
  bump_type="major_beta"
elif [[ $bump_type == "minor" ]] && [[ "$prerelease_type" == "beta" ]]; then
  bump_type="minor_beta"
elif [[ $bump_type == "patch" ]] && [[ "$prerelease_type" == "beta" ]]; then
  bump_type="patch_beta"
elif [[ $bump_type == "major" ]] && [[ "$prerelease_type" == "demo" ]]; then
  bump_type="major_demo"
elif [[ $bump_type == "minor" ]] && [[ "$prerelease_type" == "demo" ]]; then
  bump_type="minor_demo"
elif [[ $bump_type == "patch" ]] && [[ "$prerelease_type" == "demo" ]]; then
  bump_type="patch_demo"
elif [[ $bump_type == "build" ]] && [[ "$prerelease_type" == "alpha" ]] && [[ -z $prerelease_label ]]; then
  bump_type="build_alpha"
elif [[ $bump_type == "build" ]] && [[ "$prerelease_type" == "beta" ]] && [[ -z $prerelease_label ]]; then
  bump_type="build_beta"
elif [[ $bump_type == "build" ]] && [[ "$prerelease_type" == "demo" ]] && [[ -z $prerelease_label ]]; then
  bump_type="build_demo"
else
  echo "No two types of labels"
fi

if [[ -z "$prerelease_label" ]] && [[ $bump_type == "build" ]] && [[ -z $prerelease_type ]]; then
  bump_type="patch_alpha"
fi

echo "Bump type is $bump_type"

# If there are no labels and no prerelease part, create prerelease alpha with build number 0
if [ -z "$labels" ] && [ -z "$prerelease_label" ]; then
  new_prerelease_label="alpha"
  new_build_number=0
elif [ -z "$prerelease_label" ]; then
  # If prerelease suffix doesn't exist, create default prerelease alpha with build number 0
  new_prerelease_label="alpha"
  new_build_number=0
fi

# If prerelease labels are present, prioritize them
if [ -n "$labels" ]; then
  if [[ $labels == *"pre:demo"* ]]; then
    new_prerelease_label="demo"
  elif [[ $labels == *"pre:beta"* ]] && [[ $prerelease_label == "demo" ]]; then
    new_prerelease_label="demo"
  elif [[ $labels == *"pre:alpha"* ]] && [[ $prerelease_label == "demo" ]]; then
    new_prerelease_label="demo"
  elif [[ $labels == *"pre:alpha"* ]] && [[ $prerelease_label == "beta" ]]; then
    new_prerelease_label="beta"
  elif [[ $labels == *"pre:beta"* ]]; then
    new_prerelease_label="beta"
  elif [[ $labels == *"pre:alpha"* ]]; then
    new_prerelease_label="alpha"
  fi
fi

# If prerelease labels are present, bump the build number only for the highest priority prerelease type
if [ -n "$new_prerelease_label" ] && ([ -z "$prerelease_label" ] || [ "$new_prerelease_label" != "$prerelease_label" ]); then
  prerelease_label="$new_prerelease_label"
  new_build_number=0
elif [ -n "$new_prerelease_label" ]; then
  build_number=$((build_number + 1))
fi

# Bump major, minor, or patch version based on the determined bump type
case $bump_type in
"major")
  if [[ $current_version == v* ]]; then
    major_version=$(echo $current_version | sed -E 's/^v([0-9]+).*$/\1/')
    new_version="v$((major_version + 1)).0.0"
  else
    new_version=$(echo $current_version | awk -F. '{print $1 + 1 ".0.0"}')
  fi
  ;;
"minor")
  new_version=$(echo $current_version | awk -F. '{print $1 "." $2 + 1 ".0"}')
  ;;
"patch")
  new_version=$(echo $current_version | awk -F. '{print $1 "." $2 "." $3 + 1}')
  ;;
"major_alpha")
  if [[ $current_version == v* ]]; then
    major_version=$(echo $current_version | sed -E 's/^v([0-9]+).*$/\1/')
    new_version="v$((major_version + 1)).0.0-alpha.0"
  else
    new_version=$(echo $current_version | awk -F. '{print $1 + 1 ".0.0"}')
  fi
  ;;
"minor_alpha")
  new_version=$(echo $current_version | awk -F. '{print $1 "." $2 + 1 ".0"}')-alpha.0
  ;;
"patch_alpha")
  new_version=$(echo $current_version | awk -F. '{print $1 "." $2 "." $3 + 1}')-alpha.0
  ;;
"major_beta")
  if [[ $current_version == v* ]]; then
    major_version=$(echo $current_version | sed -E 's/^v([0-9]+).*$/\1/')
    new_version="v$((major_version + 1)).0.0-beta.0"
  else
    new_version=$(echo $current_version | awk -F. '{print $1 + 1 ".0.0"}')
  fi
  ;;
"minor_beta")
  new_version=$(echo $current_version | awk -F. '{print $1 "." $2 + 1 ".0"}')-beta.0
  ;;
"patch_beta")
  new_version=$(echo $current_version | awk -F. '{print $1 "." $2 "." $3 + 1}')-beta.0
  ;;
"major_demo")
  if [[ $current_version == v* ]]; then
    major_version=$(echo $current_version | sed -E 's/^v([0-9]+).*$/\1/')
    new_version="v$((major_version + 1)).0.0-demo.0"
  else
    new_version=$(echo $current_version | awk -F. '{print $1 + 1 ".0.0"}')
  fi
  ;;
"minor_demo")
  new_version=$(echo $current_version | awk -F. '{print $1 "." $2 + 1 ".0"}')-demo.0
  ;;
"patch_demo")
  new_version=$(echo $current_version | awk -F. '{print $1 "." $2 "." $3 + 1}')-demo.0
  ;;
"build_alpha")
  new_version=$(echo $current_version | awk -F. '{print $1 "." $2 "." $3 + 1}')-alpha.0
  ;;
"build_beta")
  new_version=$(echo $current_version | awk -F. '{print $1 "." $2 "." $3 + 1}')-beta.0
  ;;
"build_demo")
  new_version=$(echo $current_version | awk -F. '{print $1 "." $2 "." $3 + 1}')-demo.0
  ;;
"build")
  # If there are prerelease labels, include them in the new version
  if [ -n "$prerelease_label" ] && [ -n "$new_build_number" ]; then
    new_version="${current_version%-*}-$prerelease_label.$new_build_number"
  elif [ -n "$prerelease_label" ] && [ "$new_prerelease_label" == "$prerelease_label" ]; then
    new_version="${current_version%-*}-$prerelease_label.$build_number"
  elif [ -n "$prerelease_label" ] && [ -z "$new_prerelease_label" ]; then
    new_version="${current_version%-*}-$prerelease_label.$((build_number + 1))"
  else
    new_version="${current_version%-*}.$build_number"

    # If there is no prerelease label, but the current version has the format "v0.25.17-alpha.1"
    if [[ $current_version =~ -alpha.[0-9]+$ ]]; then
      new_version="${current_version%-*}-alpha.$((build_number - 1))"
    fi
  fi
  ;;
*)
  echo "Invalid bump type"
  exit 1
  ;;
esac
validate_version "$new_version"
echo "Bumping $bump_type Version"
echo "Current Version: $current_version"
echo "Labels attached to the Pull Request: $labels"
echo "New Version: $new_version"
echo "sha=$(git rev-parse HEAD)" >> $GITHUB_OUTPUT
echo "sha_short=$(git rev-parse --short HEAD)" >> $GITHUB_OUTPUT
echo "new_version=$new_version" >> $GITHUB_OUTPUT
echo "current_version=$current_version" >> $GITHUB_OUTPUT
