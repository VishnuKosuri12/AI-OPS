WRMCB=function(e){var c=console;if(c&&c.log&&c.error){c.log('Error running batched script.');c.error(e);}}
;
try {
/* module-key = 'com.atlassian.confluence.plugins.confluence-create-content-plugin:create-from-template-macro-browser-resources', location = 'com/atlassian/confluence/plugins/createcontent/js/create-from-template-macro-fields.js' */
AJS.toInit(function ($) {

    /**
     * @param {String} spaceKey
     * @param {function(!Object, !Object)} callback
     */
    function getWebItemsSync(spaceKey, callback) {
        Confluence.Blueprint.Dialog.requestWebItems(spaceKey, false).done(function (ev) {
            var configs = Confluence.Blueprint.Dialog.loadedWebitems[spaceKey];
            if (_.isEmpty(configs)) {
                AJS.log('create-from-template-macro-fields: No Create dialog web items found for spaceKey >' + spaceKey + '<');
                return;
            }

            callback(ev, configs);

        }).fail(function () {
            AJS.log('create-from-template-macro-fields: requestWebItems call for spaceKey >' + spaceKey + '< failed');
        });
    }

    function fillField(input, spaceKey, selectedParams) {
        getWebItemsSync(spaceKey, function(ev, configs) {
            var selected = input.val();
            input.empty();
            _.each(configs, function(config) {
                var itemModuleCompleteKey = config.itemModuleCompleteKey;
                // Blank pages and blog posts have now a contentBlueprintId - so we need to skip them somehow
                // As the macro does not support creating content from them
                if ((itemModuleCompleteKey == "com.atlassian.confluence.plugins.confluence-create-content-plugin:create-blank-page"
                        || itemModuleCompleteKey == "com.atlassian.confluence.plugins.confluence-create-content-plugin:create-blog-post"))
                    return;
                if (!(config.templateId || config.contentBlueprintId))
                    return;
                var option = $('<option></option>').text(config.name);
                option.attr("data-template-id", config.templateId);
                option.attr("data-blueprint-module-complete-key", config.blueprintModuleCompleteKey);
                option.attr("data-content-blueprint-id", config.contentBlueprintId);
                option.attr("data-create-result", config.createResult);
                option.val(config.templateId || config.contentBlueprintId);
                input.append(option);
                //In some cases, selectedParams might have incorrect/stale template selection used in the template dropdown. Updating it to latest.
                //https://hello.atlassian.net/browse/CTE-1686
                if(config.blueprintModuleCompleteKey && selectedParams && selectedParams.blueprintModuleCompleteKey &&
                    config.blueprintModuleCompleteKey === selectedParams.blueprintModuleCompleteKey) {
                    selectedParams.templateName = config.contentBlueprintId;
                }
            });
            //select the original template, if present, otherwise .val() will default to the first option.
            input.val(selected);
        });
    }

    //note - this method contains an async API call
    function handlePageTypeField(spaceKey) {
        if (!AJS.DarkFeatures.isEnabled("cft_macro_live_doc_support")) {
            return;
        }

        //check async if live docs are enabled in the space
        //show/hide the page type selection dropdown accordingly
        $.ajax({
            url: Confluence.getContextPath() + "/rest/internals/latest/live-pages-enabled",
            dataType: "json",
            data: {
                spaceKey: spaceKey
            },
        }).done(function (data) {
            AJS.MacroBrowser.fields["pageType"].paramDiv.toggleClass("hidden", !data);
        }).fail(function (error) {
            AJS.log('Error fetching live docs enablement state', error);
            AJS.MacroBrowser.fields["pageType"].paramDiv.toggleClass("hidden", false);
        });
    }

    //selection for whether to create a page or live doc
    function initPageTypeDropdown() {
        var input = $("#macro-param-pageType");
        input.append($('<option></option>').text("Page").val("page"));
        input.append($('<option></option>').text("Live doc").val("live"));
        //hide by default till we fully roll out
        AJS.MacroBrowser.fields["pageType"].paramDiv.addClass("hidden");
    }

    //new set of string to be rolled out behind a FG
    function maybeInitV2Strings() {
        if (!AJS.DarkFeatures.isEnabled("cft_macro_live_doc_support")) {
            return;
        }
        var templateDesc = AJS.MacroBrowser.fields["templateName"].paramDiv.children('div.macro-param-desc');
        templateDesc.text("Select template for newly created content.");

        var titleDesc = AJS.MacroBrowser.fields["title"].paramDiv.children('div.macro-param-desc');
        titleDesc.text("Add @currentDate, @spaceName or @spaceKey to include those values.");

        var titleLabel = AJS.MacroBrowser.fields["title"].paramDiv.children('label');
        titleLabel.text("Title of content");

        var spaceKeyDesc = AJS.MacroBrowser.fields["spaceKey"].paramDiv.children('div.macro-param-desc');
        spaceKeyDesc.text("Designate where new content will be added. Will default to current space.");
    }

    var overrides = {
        fields: {
            "spacekey" : {
                "spaceKey" : function spaceKeyField(param) {
                    var field = AJS.MacroBrowser.ParameterFields["spacekey"](param),
                        currentSpace = field.input.val();

                    var refreshTemplateList = function() {
                        var newSpace = field.input.val();
                        if (newSpace != currentSpace) {
                            //handle page type dropdown async while template load below this
                            handlePageTypeField(newSpace);
                            fillField(AJS.MacroBrowser.fields['templateName'].input, newSpace, null);
                        }
                        currentSpace = newSpace;
                    };

                    //change events are swallowed by the macro browser space key autocomplete so we need to
                    //use blur and check if the value changed.
                    field.input.bind("selected.autocomplete-content", refreshTemplateList);
                    field.input.blur(refreshTemplateList);

                    return field;
                }
            }
        },

        beforeParamsSet: function beforeParamSetOverride(selectedParams, selectedMacro) {
            //Set button label to current buttonLabel OR createButtonLabel (old style) or Default text.
            selectedParams.buttonLabel = selectedParams.buttonLabel || selectedParams.createButtonLabel || "Create from template";
            selectedParams.spaceKey = AJS.Meta.get("space-key");
            maybeInitV2Strings();
            initPageTypeDropdown();
            //handle page type dropdown async while template load below this
            handlePageTypeField(selectedParams.spaceKey);
            fillField($("#macro-param-templateName"), selectedParams.spaceKey, selectedParams);

            return selectedParams;
        },

        beforeParamsRetrieved: function beforeParamsRetrievedOverride(paramMap, macro, sharedParamMap) {
            var option = AJS.MacroBrowser.fields['templateName'].input.find("option:selected");
            paramMap["blueprintModuleCompleteKey"] = option.data("blueprint-module-complete-key");
            paramMap["contentBlueprintId"] = option.data("content-blueprint-id");
            paramMap["templateId"] = option.attr("data-template-id");
            paramMap["createResult"] = option.data("create-result");
            return paramMap;
        }
    };

    AJS.MacroBrowser.setMacroJsOverride("create-from-template", overrides);
});

}catch(e){WRMCB(e)};