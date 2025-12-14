import { Command } from 'commander';

const getOptions = () => {
  const command = new Command()
    .option('--name <name>', 'specific name', 'unknown')
    .parse(process.argv)
    .opts();

  const name: string = command['name'];
  return { name };
};

const main = async () => {
  const { name } = getOptions();
  return `hello world, ${name}!`;
};

main()
  .then((result) => {
    console.log(result);
    process.exit(0);
  })
  .catch((e) => {
    console.error(e);
    process.exit(1);
  });
