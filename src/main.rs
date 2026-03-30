use playwright_rs::{Browser, BrowserContext, LaunchOptions, Page, Playwright, Response};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let playwright = Playwright::launch().await?;
    let chromium = playwright.chromium();
    println!("Default path: {}", chromium.executable_path());
    let browser = chromium
        .launch_with_options(
            LaunchOptions::new()
                .headless(false)
                .executable_path(chromium.executable_path().to_string())
                .args(vec![
                    "--ozone-platform=wayland".to_string(),
                    "--enable-features=WaylandWindowDecorations".to_string(),
                ]),
        )
        .await?;
    let context = browser.new_context().await?;
    let (page, response) = goto_iclinic(context).await?;

    println!("Title: {}", page.title().await?);
    println!("Status: {}", response.status());

    println!(
        "{}",
        page.locator(".loginMessage")
            .await
            .text_content()
            .await?
            .expect("Should find login message")
    );

    Ok(())
}

async fn goto_iclinic(
    context: BrowserContext,
) -> Result<(Page, Response), Box<dyn std::error::Error>> {
    let page = context.new_page().await?;
    let response = page
        .goto("https://login.mdland.com/login_central.aspx", None)
        .await?
        .expect("Should return a response");
    Ok((page, response))
}
