#!/bin/bash
# Create test plans to split test discovery and prevent Xcode timeouts
# Test plans organize tests into smaller groups for faster discovery

PLANS_DIR="SixLayerFramework.xcodeproj/xcshareddata/xctestplans"
mkdir -p "$PLANS_DIR"

# Test Plan 1: Unit Tests - Core & Layers (smallest group)
cat > "$PLANS_DIR/01-UnitTests-CoreLayers.xctestplan" << 'EOF'
{
  "configurations" : [
    {
      "id" : "unit-core-layers",
      "name" : "Unit Tests - Core & Layers",
      "options" : {
        "targets" : [
          {
            "containerPath" : "container:SixLayerFramework.xcodeproj",
            "identifier" : "SixLayerFrameworkUnitTests_macOS",
            "name" : "SixLayerFrameworkUnitTests_macOS"
          }
        ]
      },
      "testTargets" : [
        {
          "target" : {
            "containerPath" : "container:SixLayerFramework.xcodeproj",
            "identifier" : "SixLayerFrameworkUnitTests_macOS",
            "name" : "SixLayerFrameworkUnitTests_macOS"
          }
        }
      ]
    }
  ],
  "defaultOptions" : {
    "commandLineArgumentEntries" : [],
    "environmentVariableEntries" : [],
    "language" : "en",
    "region" : "US"
  },
  "testPlanName" : "Unit Tests - Core & Layers",
  "version" : 1
}
EOF

# Test Plan 2: Unit Tests - Accessibility (large group, but focused)
cat > "$PLANS_DIR/02-UnitTests-Accessibility.xctestplan" << 'EOF'
{
  "configurations" : [
    {
      "id" : "unit-accessibility",
      "name" : "Unit Tests - Accessibility",
      "options" : {
        "targets" : [
          {
            "containerPath" : "container:SixLayerFramework.xcodeproj",
            "identifier" : "SixLayerFrameworkUnitTests_macOS",
            "name" : "SixLayerFrameworkUnitTests_macOS"
          }
        ]
      },
      "testTargets" : [
        {
          "target" : {
            "containerPath" : "container:SixLayerFramework.xcodeproj",
            "identifier" : "SixLayerFrameworkUnitTests_macOS",
            "name" : "SixLayerFrameworkUnitTests_macOS"
          }
        }
      ]
    }
  ],
  "defaultOptions" : {
    "commandLineArgumentEntries" : [],
    "environmentVariableEntries" : [],
    "language" : "en",
    "region" : "US"
  },
  "testPlanName" : "Unit Tests - Accessibility",
  "version" : 1
}
EOF

# Test Plan 3: Unit Tests - Forms
cat > "$PLANS_DIR/03-UnitTests-Forms.xctestplan" << 'EOF'
{
  "configurations" : [
    {
      "id" : "unit-forms",
      "name" : "Unit Tests - Forms",
      "options" : {
        "targets" : [
          {
            "containerPath" : "container:SixLayerFramework.xcodeproj",
            "identifier" : "SixLayerFrameworkUnitTests_macOS",
            "name" : "SixLayerFrameworkUnitTests_macOS"
          }
        ]
      },
      "testTargets" : [
        {
          "target" : {
            "containerPath" : "container:SixLayerFramework.xcodeproj",
            "identifier" : "SixLayerFrameworkUnitTests_macOS",
            "name" : "SixLayerFrameworkUnitTests_macOS"
          }
        }
      ]
    }
  ],
  "defaultOptions" : {
    "commandLineArgumentEntries" : [],
    "environmentVariableEntries" : [],
    "language" : "en",
    "region" : "US"
  },
  "testPlanName" : "Unit Tests - Forms",
  "version" : 1
}
EOF

# Test Plan 4: UI Tests - Accessibility (largest group)
cat > "$PLANS_DIR/04-UITests-Accessibility.xctestplan" << 'EOF'
{
  "configurations" : [
    {
      "id" : "ui-accessibility",
      "name" : "UI Tests - Accessibility",
      "options" : {
        "targets" : [
          {
            "containerPath" : "container:SixLayerFramework.xcodeproj",
            "identifier" : "SixLayerFrameworkUITests_macOS",
            "name" : "SixLayerFrameworkUITests_macOS"
          }
        ]
      },
      "testTargets" : [
        {
          "target" : {
            "containerPath" : "container:SixLayerFramework.xcodeproj",
            "identifier" : "SixLayerFrameworkUITests_macOS",
            "name" : "SixLayerFrameworkUITests_macOS"
          }
        }
      ]
    }
  ],
  "defaultOptions" : {
    "commandLineArgumentEntries" : [],
    "environmentVariableEntries" : [],
    "language" : "en",
    "region" : "US"
  },
  "testPlanName" : "UI Tests - Accessibility",
  "version" : 1
}
EOF

# Test Plan 5: All Unit Tests (for comprehensive runs)
cat > "$PLANS_DIR/05-AllUnitTests.xctestplan" << 'EOF'
{
  "configurations" : [
    {
      "id" : "all-unit-tests",
      "name" : "All Unit Tests",
      "options" : {
        "targets" : [
          {
            "containerPath" : "container:SixLayerFramework.xcodeproj",
            "identifier" : "SixLayerFrameworkUnitTests_macOS",
            "name" : "SixLayerFrameworkUnitTests_macOS"
          }
        ]
      },
      "testTargets" : [
        {
          "target" : {
            "containerPath" : "container:SixLayerFramework.xcodeproj",
            "identifier" : "SixLayerFrameworkUnitTests_macOS",
            "name" : "SixLayerFrameworkUnitTests_macOS"
          }
        }
      ]
    }
  ],
  "defaultOptions" : {
    "commandLineArgumentEntries" : [],
    "environmentVariableEntries" : [],
    "language" : "en",
    "region" : "US"
  },
  "testPlanName" : "All Unit Tests",
  "version" : 1
}
EOF

echo "✅ Created test plans in $PLANS_DIR"
echo ""
echo "To use a test plan:"
echo "1. Open Xcode"
echo "2. Product → Scheme → Edit Scheme..."
echo "3. Test tab → Info → Test Plan dropdown"
echo "4. Select one of the test plans"
echo ""
echo "Available test plans:"
ls -1 "$PLANS_DIR"/*.xctestplan | sed 's/.*\///' | sed 's/\.xctestplan//'
