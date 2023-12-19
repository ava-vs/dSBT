<script>
    import Card from "./Card.svelte";

    // Demo data
    let website = "https://ava.capetown/en";
    let icp_link = "https://internetcomputer.org";
    let badgeReceipt = {
        owner: "Ivone Drake",
        userId: 2300900923,
        reputation: {
            total: 695,
            specialist: [
                {
                    code: "1.2.3.4",
                    name: "Motoko",
                },
                {
                    code: "7.2.2.45",
                    name: "Texas Holdem",
                },
            ],
            expert: [
                {
                    code: "1.2.2.1",
                    name: "Internet Computer Core",
                },
            ],
            evolution: "https://ava.capetown/user/",
        },
    };

    let evolution_link =
        badgeReceipt.reputation.evolution + badgeReceipt.userId?.toString() ??
        "";
    
</script>

<main>
    <h1>Component Demo</h1>
    <div class="card">
        <div class="card-header">
            <a href={website} target="_blank" class="card-logo-link"
                ><div class="card-logo"></div></a
            >

            <div class="title">
                <img src="card-title-not-filled.svg" alt="dSBT" />
            </div>

            <div class="card-reputation">
                <div class="reputation-icon"></div>
                <div class="reputation-value">
                    {badgeReceipt.reputation.total}
                </div>
            </div>
        </div>
        <div class="card-content">
            <div class="card-info">
                <div class="info-item">
                    <span class="info-label">Name:</span>
                    <span class="info-value" id="name"
                        >{badgeReceipt.owner}</span
                    >
                </div>
                <div class="info-item">
                    <span class="info-label">Specialist:</span>
                    <span
                        class="info-value"
                        id="specialist"
                        title={badgeReceipt.reputation.specialist
                            .map((s) => s.name)
                            .join("; ")}
                    >
                        {badgeReceipt.reputation.specialist
                            .map((s) => s.code)
                            .join("; ")}
                        <a
                            href={evolution_link}
                            target="_blank"
                            class="card-logo-link"
                            ><img
                                src="arrow.svg"
                                id="specialist-arrow"
                                alt="arrow"
                                title="Click to see more"
                            /></a
                        ></span
                    >
                </div>
                <div class="info-item">
                    <span class="info-label">Expert:</span>
                    <span
                        class="info-value"
                        id="expert"
                        title={badgeReceipt.reputation.expert
                            .map((s) => s.name)
                            .join("; ")}
                        >{badgeReceipt.reputation.expert
                            .map((s) => s.code)
                            .join("; ")}<a
                            href={evolution_link}
                            target="_blank"
                            class="card-logo-link"
                            ><img
                                src="arrow.svg"
                                id="expert-arrow"
                                alt="arrow"
                                title="Click to see more"
                            /></a
                        ></span
                    >
                </div>
            </div>
            <div class="footer">
                <a href={evolution_link} target="_blank" class="evolution-link"
                    ><img src="evolution.svg" alt="Evolution link" /></a
                >
                <div class="icp-icon">
                    <a href={icp_link} target="_blank" class="icp-logo"
                        ><img src="icp-logo.svg" alt="ICP link" /></a
                    >
                </div>
            </div>
        </div>
    </div>
    <Card />
</main>

<style>
    :root {
        /* font sizes */
        --font-size-base: 16px;
        --font-size-less: 12px;

        /* Colors */
        --primary-color: #ee4817;
        --color-white: #fff;

        /* Gaps */
        --gap-xl: 20px;

        /* Paddings */
        --padding-3xs: 10px;
        --padding-13xl: 32px;
    }
    .card-header::before,
    .card-header::after {
        content: "";
        flex: 1;
    }

    .card-logo-link {
        display: inline-block;
    }

    .card-logo,
    .card-reputation {
        flex: 0;
    }

    .title {
        flex: 0;
    }

    .card {
        display: flex;
        flex-direction: column;
        width: 21.875rem;
        height: 22.25rem;
        border-radius: 0.625rem;
        border: 1px solid #fff;
        background: linear-gradient(161deg, #00155d 8.46%, #013440 91.91%);
        background-image: url("card-background.svg");
        color: var(--color-white);
        overflow: hidden;
    }

    .card-header {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 95%;
        padding: 1rem;
        background-color: transparent;
    }

    .title {
        flex-shrink: 0;
        padding: 0;
    }

    .card-logo {
        background-image: url("aVa_logo.png");
        background-size: contain;
        background-repeat: no-repeat;
        min-width: 50px;
        height: 40px;
        flex-shrink: 0;
        margin-right: 1rem;
    }

    .card-reputation {
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
        margin-left: auto;
        margin-right: 0.5rem;
    }

    .reputation-icon {
        background-image: url("rep2.svg");
        background-size: contain;
        background-repeat: no-repeat;
        min-width: 50px;
        height: 80px;
        margin-left: 0.5rem;
    }

    .reputation-value {
        text-align: right;
        color: var(--color-white);
        font-family:  "Montserrat","Goldman", sans-serif;
        font-size: 1.2rem;
        margin-left: 0.5rem;
    }

    .card-content {
        font-family: "Montserrat", "Goldman", sans-serif; 
        padding: 16px; 
        text-align: left; 
        font-size: var(--font-size-base); 
        color: var(--color-white); 
    }

    .card-info {
        margin-bottom: 16px;
        font-family: "Montserrat", "Goldman", sans-serif;
    }

    .info-item {
        display: flex;
        align-items: center;
        margin-bottom: 8px;
    }
                      
    .info-label {
        font-size: var(--font-size-less);
        /* font-weight: bold; */
        width: 120px; 
        text-align: right;
        color: #07d1fd; 
        margin-right: 1rem;
        flex-shrink: 0;
    }
                      
    .info-value {
        font-size: var(--font-size-less);
        color: var(--color-white);
        border-bottom: 1px solid #07d1fd; 
        padding-bottom: 3px;
        position: relative;
    }

    .info-value a {
        color: inherit; 
        text-decoration: inherit; 
    }
    .info-value img {
        vertical-align: middle;
        margin-left: 0.5rem; 
    }

    #expert-arrow,
    #specialist-arrow {
        vertical-align: middle; 
        margin-left: 8px; 
    }

    .footer {
        display: flex;
    }

    .evolution-link {
        margin-top: 10px;
    }
    .icp-icon {
        display: flex;
        min-width: 50px;
        flex-shrink: 0;
        margin-left: 35%;
        margin-top: 15%;
    }
</style>
