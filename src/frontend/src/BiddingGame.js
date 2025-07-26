import React, { useState, useEffect } from "react";
import axios from "axios";

// Enhanced styles for a game show look and feel
const styles = {
    // ... (All the styling from the previous response remains the same)
    container: {
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        fontFamily: "'Helvetica Neue', Arial, sans-serif",
        background: 'linear-gradient(to right, #007bff, #0056b3)',
        minHeight: '100vh',
        padding: '20px',
        color: 'white',
    },
    header: {
        fontSize: '3.5em',
        fontWeight: 'bold',
        textShadow: '2px 2px 4px rgba(0,0,0,0.4)',
        marginBottom: '30px',
    },
    productContainer: {
        border: '4px solid #ffc107', // Gold border
        borderRadius: '15px',
        padding: '30px',
        backgroundColor: 'rgba(255, 255, 255, 0.1)',
        boxShadow: '0 8px 16px rgba(0,0,0,0.3)',
        textAlign: 'center',
        width: 'clamp(300px, 80%, 500px)', // Responsive width
    },
    productImage: {
        width: '100%',
        height: 'auto',
        maxHeight: '300px',
        objectFit: 'contain',
        marginBottom: '20px',
        borderRadius: '8px',
        backgroundColor: 'white',
        padding: '10px',
    },
    productName: {
        fontSize: '2em',
        fontWeight: 'bold',
        marginBottom: '25px',
        color: '#ffc107', // Gold text
    },
    input: {
        padding: '12px',
        fontSize: '1.2em',
        border: '2px solid #ddd',
        borderRadius: '8px',
        marginBottom: '20px',
        width: '80%',
        textAlign: 'center',
    },
    button: {
        padding: '12px 25px',
        fontSize: '1.2em',
        border: 'none',
        borderRadius: '8px',
        cursor: 'pointer',
        color: 'white',
        fontWeight: 'bold',
        transition: 'transform