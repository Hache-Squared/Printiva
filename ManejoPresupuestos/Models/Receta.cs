using System.ComponentModel.DataAnnotations;

namespace ManejoPresupuestos.Models
{
    public class Receta
    {
        public int RecetaId { get; set; }

        [Required(ErrorMessage = "El campo {0} es obligatorio")]
        [StringLength(maximumLength: 100, ErrorMessage = "No puede ser mayor a {1} caracteres")]
        public string Nombre { get; set; }

        public int[] InventariosIds { get; set; }
    }
}
