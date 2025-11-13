import typer

app = typer.Typer(help="Command-line interface.")


@app.command("hello")
def hello(name: str = typer.Option(None, help="Username to greet.")):
    typer.echo(f"Hello { name or 'World' }!")


if __name__ == "__main__":
    app()
