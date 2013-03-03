## Usage

In a git directory, execute:

    vim +Gapply

You'll get a diff, just like from `git diff | vim -`, except you can delete
patches and when you save, the current state of the diff will be applied to
the index. Afterwards, you can commit with `git commit`.

## Contributing

Pull requests are welcome, but take a look at [CONTRIBUTING.md](https://github.com/AndrewRadev/gapply.vim/blob/master/CONTRIBUTING.md) first for some guidelines.
