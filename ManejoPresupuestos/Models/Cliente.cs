using System.ComponentModel.DataAnnotations;

namespace ManejoPresupuestos.Models
{
    public class Cliente
    {
        public int ClienteId { get; set; }
        public int UsuarioId { get; set; }

        [Required]
        [StringLength(150)]
        public string Nombre { get; set; } = string.Empty;

        [StringLength(80)]
        public string? ApellidoPaterno { get; set; }

        [StringLength(80)]
        public string? ApellidoMaterno { get; set; }

        [StringLength(30)]
        public string? Telefono { get; set; }

        [StringLength(80)]
        public string? Instagram { get; set; }

        [StringLength(30)]
        public string? WhatsApp { get; set; }

        [StringLength(120)]
        [EmailAddress]
        public string? Email { get; set; }

        [StringLength(250)]
        public string? Direccion { get; set; }

        public bool EsEmpresa { get; set; }

        [StringLength(13)]
        public string? RFC { get; set; }

        public DateTime FechaCreacion { get; set; }
        public bool EstaActivo { get; set; } = true;
        public DateTime? FechaActualizacion { get; set; }
    }
}