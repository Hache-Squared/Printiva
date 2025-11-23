using System.ComponentModel.DataAnnotations;

namespace ManejoPresupuestos.Models
{
    public class Cliente
    {
        public int ClienteId { get; set; }

        [Required(ErrorMessage = "El campo {0} es obligatorio")]
        [StringLength(maximumLength: 200, ErrorMessage = "No puede ser mayor a {1} caracteres")]
        public string Nombre { get; set; }

        [StringLength(maximumLength: 200, ErrorMessage = "No puede ser mayor a {1} caracteres")]
        public string? Telefono { get; set; } = null;

        [StringLength(maximumLength: 200, ErrorMessage = "No puede ser mayor a {1} caracteres")]
        public string? Correo { get; set; } = null;
    }
}
