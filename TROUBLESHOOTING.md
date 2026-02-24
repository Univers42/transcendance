# Troubleshooting to ft_transcendence

Everything you need to know to solve problem you can encounter during the development of this project. If something isn't covered here and you found the solution, just add it.

---

## Typescript dependencies
### Install NodeJS and NPM in the Virtual Machine

First of all you need to install version 22 of NodeJS. Follow these steps or visit https://nodejs.org/en/download. If you decide to visit the website, :warning: remember to select the ***version 22 of NodeJS***.

#### Download and install nvm:
`curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash`

#### In lieu of restarting the shell
`\. "$HOME/.nvm/nvm.sh"`

#### Download and install Node.js:
`nvm install 22`

#### Verify the Node.js version:
`node -v # Should print "v22.22.0".`

#### Verify npm version:
`npm -v # Should print "10.9.4".`

Once both Node and npm are installed in the VM, to solve the problem "Cannot find module ‘X’" you have two possibilities:
1. Directly install the module 'X'. For example, if the `@nestjs/testing` module cannot be found, just execute `npm install @nestjs/testing`.
2. If the first option did not solve the issue, hover the mouse over the error and execute the recommended command.

### :warning: README :warning:
As we are using Node Package Manager (npm), every time you install a dependency, both `package.json` and `package-lock.json` files will be modified. This two files contain every dependency needed by the application. So it is important to install every dependencies before starting to code.