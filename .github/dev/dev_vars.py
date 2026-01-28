"""Generate dev.tfvars for workspace tests."""

from pathlib import Path

import typer

app = typer.Typer()

WORKSPACE_DIR = Path(__file__).parent.parent.parent / "tests" / "workspace_azure_examples"
DEV_TFVARS = WORKSPACE_DIR / "dev.tfvars"

DEFAULT_ATLAS_AZURE_APP_ID = "9f2deb0d-be22-4524-a403-df531868bac0"
DEFAULT_AZURE_LOCATION = "eastus2"


@app.command()
def project(project_id: str) -> None:
    WORKSPACE_DIR.mkdir(parents=True, exist_ok=True)
    content = f'project_id = "{project_id}"\n'
    DEV_TFVARS.write_text(content)
    typer.echo(f"Generated {DEV_TFVARS}")


@app.command()
def org(org_id: str) -> None:
    WORKSPACE_DIR.mkdir(parents=True, exist_ok=True)
    content = f'org_id = "{org_id}"\n'
    DEV_TFVARS.write_text(content)
    typer.echo(f"Generated {DEV_TFVARS}")


@app.command()
def azure(
    org_id: str = typer.Option(..., envvar="MONGODB_ATLAS_ORG_ID"),
    subscription_id: str = typer.Option(..., envvar="ARM_SUBSCRIPTION_ID"),
    resource_group_name: str = typer.Option("", envvar="AZURE_RESOURCE_GROUP_NAME"),
    service_principal_id: str = typer.Option("", envvar="AZURE_SERVICE_PRINCIPAL_ID"),
    atlas_azure_app_id: str = typer.Option(DEFAULT_ATLAS_AZURE_APP_ID, envvar="ATLAS_AZURE_APP_ID"),
    azure_location: str = typer.Option(DEFAULT_AZURE_LOCATION, envvar="AZURE_LOCATION"),
    storage_account_name: str = typer.Option("", envvar="AZURE_STORAGE_ACCOUNT_NAME"),
) -> None:
    """Generate dev.tfvars from environment variables."""
    WORKSPACE_DIR.mkdir(parents=True, exist_ok=True)
    lines = [
        f'org_id = "{org_id}"',
        f'subscription_id = "{subscription_id}"',
    ]
    if resource_group_name:
        lines.append(f'resource_group_name = "{resource_group_name}"')
    else:
        typer.secho("AZURE_RESOURCE_GROUP_NAME not set, will create new", fg="yellow")
    if service_principal_id:
        lines.append(f'service_principal_id = "{service_principal_id}"')
    else:
        typer.secho("AZURE_SERVICE_PRINCIPAL_ID not set, will create new", fg="yellow")
    if atlas_azure_app_id != DEFAULT_ATLAS_AZURE_APP_ID:
        lines.append(f'atlas_azure_app_id = "{atlas_azure_app_id}"')
    else:
        typer.secho("ATLAS_AZURE_APP_ID not set, using default", fg="yellow")
    if azure_location != DEFAULT_AZURE_LOCATION:
        lines.append(f'azure_location = "{azure_location}"')
    else:
        typer.secho(
            f"AZURE_LOCATION not set, using default {DEFAULT_AZURE_LOCATION}",
            fg="yellow",
        )
    if storage_account_name:
        lines.append(f'storage_account_name = "{storage_account_name}"')
    else:
        typer.secho("AZURE_STORAGE_ACCOUNT_NAME not set, will auto-generate", fg="yellow")
    content = "\n".join(lines) + "\n"
    DEV_TFVARS.write_text(content)
    typer.echo(f"Generated {DEV_TFVARS}")


@app.command()
def tfrc(plugin_dir: str) -> None:
    """Print dev.tfrc content for provider dev_overrides."""
    content = f'''provider_installation {{
  dev_overrides {{
    "mongodb/mongodbatlas" = "{plugin_dir}"
  }}
  direct {{}}
}}
'''
    print(content, end="")


if __name__ == "__main__":
    app()
