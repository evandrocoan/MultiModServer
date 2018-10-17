AlliedModders' Files
=============================

Contains my published plugins and games configurations files for games supported on the
AlliedModders' forum. See history posting: https://forums.alliedmods.net/search.php?do=finduser&u=262504



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
$ git subtree add --squash --prefix=local_directory remote_name/master
```

Or use this single command:
```
git subtree add --squash --prefix=code file:///D:/GitDirectory/.git master
```


* In future, you can merge in additional changes as follows:
```
$ git subtree pull --squash --prefix=local_directory remote_name/master
```

* And you can push changes back upstream as follows:
```
$ git subtree push --prefix=local_directory remote_name/master
$ git subtree push --prefix=local_directory https://github.com/git/git.git master
```

1. https://stackoverflow.com/questions/23937436/add-subdirectory-of-remote-repo-with-git-subtree
1. https://stackoverflow.com/questions/20102594/git-subtree-push-squash-does-not-squash
1. https://stackoverflow.com/questions/9614255/git-subtree-push-squash-needs-a-long-time-and-it-is-getting-longer-over-time
1. https://stackoverflow.com/questions/10081681/git-subtree-push-changes-back-to-subtree-project
1. https://stackoverflow.com/questions/26928299/why-does-git-subtree-push-always-list-hundreds-of-commits
