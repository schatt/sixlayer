-- Set the active scheme in an Xcode window.
-- Usage:
--   Run with no args: prompts for scheme (and optionally window).
--   Run with scheme name: osascript set_xcode_scheme.applescript "SLF-iOS-AllTests"
--     IMPORTANT: The Xcode window for the target project must be frontmost, or you get SCHEME_NOT_FOUND.
--     (e.g. for SixLayer: click the SixLayer window, then run with "SLF-iOS-ViewInspectorTests".)
--   Run with scheme and window: osascript set_xcode_scheme.applescript "SLF-iOS-AllTests" 2
--     (window 2 = second window; 1 = frontmost)
--   Run with scheme and window title fragment: osascript set_xcode_scheme.applescript "SLF-iOS-AllTests" "SixLayer"
--     (brings first window whose title contains "SixLayer" to front, then sets scheme; may hit -10006 in some environments)

on run argv
	if (count of argv) = 0 then
		return runInteractive()
	else if (count of argv) = 1 then
		set schemeName to item 1 of argv
		set windowSelector to "front"
		return setSchemeInXcode(schemeName, windowSelector)
	else
		set schemeName to item 1 of argv
		set windowSelector to item 2 of argv
		return setSchemeInXcode(schemeName, windowSelector)
	end if
end run

on runInteractive()
	tell application "Xcode" to activate
	delay 0.3
	tell application "Xcode"
		if (count of documents) = 0 then
			display alert "No project open" message "Open a project or workspace in Xcode first."
			return "NO_DOCUMENT"
		end if
		set doc to active workspace document
		set schemeList to name of every scheme in doc
		set chosenScheme to choose from list schemeList with prompt "Choose scheme for this window:" default items (item 1 of schemeList)
		if chosenScheme is false then
			return "CANCELLED"
		end if
		set schemeName to item 1 of chosenScheme
	end tell
	return setSchemeInXcode(schemeName, "front")
end runInteractive

on setSchemeInXcode(schemeName, windowSelector)
	tell application "Xcode" to activate
	delay 0.2

	-- Bring the chosen window to front so "active workspace document" is the right one
	if windowSelector is not "front" then
		tell application "System Events"
			tell process "Xcode"
				set windowCount to count of windows
				if windowCount = 0 then
					return "NO_WINDOWS"
				end if
				try
					set sel to windowSelector as integer
					-- sel is 1-based: 1 = front, 2 = second, etc.
					if sel > 1 and sel ≤ windowCount then
						set index of window sel to 1
						delay 0.2
					end if
				on error
					-- Assume it's a title fragment
					repeat with i from 1 to windowCount
						set win to window i
						set winName to name of win
						if winName contains (windowSelector as text) then
							set index of win to 1
							delay 0.2
							exit repeat
						end if
					end repeat
				end try
			end tell
		end tell
	end if

	tell application "Xcode"
		if (count of documents) = 0 then
			return "NO_DOCUMENT"
		end if
		set doc to active workspace document
		set allSchemes to schemes in doc
		repeat with s in allSchemes
			if (name of s as text) is equal to (schemeName as text) then
				set active scheme of doc to s
				return "OK"
			end if
		end repeat
		return "SCHEME_NOT_FOUND"
	end tell
end setSchemeInXcode
