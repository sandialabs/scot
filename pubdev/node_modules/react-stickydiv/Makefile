BIN = ./node_modules/.bin
uglify = ./node_modules/.bin/uglifyjs
babel = ./node_modules/.bin/babel

install link:
	@npm $@

lint:
	./node_modules/.bin/eslint index.jsx

patch: 
	@$(call lint)
	@$(call release,patch)

minor: 
	@$(call lint) 
	@$(call release,minor)

major: 
	@$(call lint)
	@$(call release,major)

jsx: 
	@$(call lint)
	gulp	
	@$(uglify) index.js > dist/react-stickydiv.min.js

publish:
	@$(call jsx)
	@(sh bin/authors)
	@$(uglify) index.js > dist/react-stickydiv.min.js
	git commit -am "`npm view . version`" --allow-empty
	@$(call release,patch)
	git push --tags origin HEAD:master
	npm publish

define release
	npm version $(1)
endef
