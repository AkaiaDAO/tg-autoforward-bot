## Setup:
1. Add the TG API key to `/app-env`. Running `source app-env` adds it to the list of environment variables (you'll have to do it every session).
- or set `TG_API_KEY` as an environment variable in any other way you like
2. In `config/config.json` add the absolute path to the `db.json` file
3. The executable for `x86_64-pc-linux-gnu` is in the `/bin` folder. If you want to compile it for a different architecture:
- Install Crystal (https://crystal-lang.org/install/)
- Run `crystal build src/main.cr --release -o 'autoforwardbot' && mv autoforwardbot bin`
4. Download `config/config.json`, `bin/autoforwardbot` and `db/db.json`
5. Run `./autoforwardbot -p "/absolute/path/to/config.json"`

## Contributors

- [your-name-here](https://github.com/your-github-user) - creator and maintainer
