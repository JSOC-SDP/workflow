$(OBJDIR)::
	+@[ -d $@/workflow/apps ] || mkdir -p $@/workflow/apps
	+@[ -d $@/../include/workflow ] || mkdir -p $@/../include/workflow
