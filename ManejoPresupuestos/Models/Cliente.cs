using System.ComponentModel.DataAnnotations;

namespace ManejoPresupuestos.Models
{
    public class Cliente
    {
        public int ClienteId { get; set; }
        public int UsuarioId { get; set; }

        [Required(ErrorMessage = "El campo {0} es obligatorio")]
        [StringLength(150)]
        public string Nombre { get; set; } = string.Empty;

        [StringLength(30)]
        public string? Telefono { get; set; }

        [StringLength(80)]
        public string? Instagram { get; set; }

        [StringLength(30)]
        public string? WhatsApp { get; set; }

        [StringLength(120)]
        [EmailAddress(ErrorMessage = "Email inválido")]
        public string? Email { get; set; }

        [StringLength(250)]
        public string? Direccion { get; set; }

        public DateTime FechaCreacion { get; set; }

        // NUEVO: borrado lógico
        public bool EstaActivo { get; set; } = true;

        public DateTime? FechaActualizacion { get; set; }
    }
}