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

### :warning: Why `pnpm` and not `npm` :warning:

#### AI answer

Pnpm is often preferred over npm because it offers significant disk space savings (50-70%) through hard-linking and provides faster installation speeds, especially in continuous integration environments. Additionally, pnpm's structure helps avoid issues with phantom dependencies, making it a better choice for complex projects and monorepos.

##### Useful links
- https://www.geeksforgeeks.org/node-js/pnpm-vs-npm/



Once both Node and npm are installed in the VM, to solve the problem "Cannot find module ‘X’" you have two possibilities:
1. Directly install the module 'X'. For example, if the `@nestjs/testing` module cannot be found, just execute `pnpm install @nestjs/testing`.
2. If the first option did not solve the issue, hover the mouse over the error and execute the recommended command.

### :warning: README :warning:
As we are using Performant Node Package Manager (pnpm), every time you install a dependency, both `package.json`, `package-lock.json`, `and pnpm-lock.yaml` files will be modified. These files contain every dependency needed by the application. So it is important to install every dependencies before starting to code.

When executing `pnpm i`, every package will be installed locally in the VM and will remove only visual errors to avoid getting mad while coding.