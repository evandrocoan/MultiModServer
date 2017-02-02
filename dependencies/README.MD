AlliedModders' Files
=============================

Contains my published plugins and games configurations files for games supported on the 
AlliedModders' forum. See history posting: https://forums.alliedmods.net/search.php?do=finduser&u=262504




## The Git Flow

This project use/try to follow the gitflow: 

1. http://nvie.com/posts/a-successful-git-branching-model/

To contribute, fork this project and checkout to the 'develop' branch to proceed with your updates.
The master branch is updated over an new plugin official release, while the 'develop' branch
receives/stores all the updates which are waiting to be released on the next version. The updates
to the 'develop' branch are usually done by merging into it, feature branches. Such approaches are
well explained on gitflow tutorials, as the one just above.



## Git Subtrees

These projects are mostly coming from another repositories, so to work with them based on its
original locations there are some special commands to use as:
```
1. git subtree add --prefix=SubProjectName https://github.com/User/SubProjectName master
2. git subtree pull --prefix=SubProjectName https://github.com/User/SubProjectName develop
3. git subtree push --prefix=SubProjectName https://github.com/User/SubProjectName develop
```

If you prefer to avoid repeating the repository URL, then you can add it as a remote:

* Do this the first time:
```
$ git remote add -f -t master --no-tags remote_name https://github.com/git/git.git
$ git subtree add --squash --prefix=third_party/git remote_name/master
```

* In future, you can merge in additional changes as follows:
```
$ git subtree pull --squash --prefix=third_party/git remote_name/master
```

* And you can push changes back upstream as follows:
```
$ git subtree push --prefix=third_party/git remote_name/master
```

* Or possibly (not sure what the difference is):
```
$ git subtree push --squash --prefix=third_party/git remote_name/master
```

1. [Add subdirectory of remote repo with git-subtree](http://stackoverflow.com/q/23937436/4934640)




