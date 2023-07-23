#[tokio::main]
async fn main() -> std::io::Result<()> {
    chromacity::run().await;
    Ok(())
}
