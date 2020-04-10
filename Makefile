.PHONY: py-format py-check-style

py-format:
	@echo "$(BOLD)Formatting Python code$(RESET)"
	@autopep8 --recursive --in-place .

py-check-style:
	@echo "$(BOLD)Running flake8$(RESET)"
	@flake8
