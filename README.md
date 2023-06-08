# Microsoft Power Query SDK Tools (Preview)

This package contains command line utilities used by the [Power Query SDK for VS Code](https://github.com/microsoft/vscode-powerquery-sdk)
for the [development of custom data connectors](https://docs.microsoft.com/en-us/power-query/startingtodevelopcustomconnectors).

## Purpose

1. To support the development of Custom Connectors with the Power Query SDK for VS Code
2. For testing Custom Connectors outside of VS Code

Usage scenarios other than those described above are not supported.

Please see the license included with this nuget package for details.

## Limitations

* Query evaluation requires a custom connector file (.mez or .pqx)
* Query output is limited to 1000 rows
* Supports the limited set of M data source functions meant for extensibility

## Support

Please note that the tools contained within this nuget package are not supported by the Microsoft Customer Support team.

The support policy for the tools contained within this package can be found on the [Power Query SDK for VS Code site](https://github.com/microsoft/vscode-powerquery-sdk/blob/main/SUPPORT.md).
