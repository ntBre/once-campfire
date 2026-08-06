compose := "docker compose -f compose.dev.yaml"

test:
	{{compose}} run --rm -e RAILS_ENV=test campfire bin/rails test

lint:
	{{compose}} run --rm -e RAILS_ENV=test campfire bin/rubocop

brakeman:
	{{compose}} run --rm -e RAILS_ENV=test campfire bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error

run:
	{{compose}} up

shutdown:
	{{compose}} down
